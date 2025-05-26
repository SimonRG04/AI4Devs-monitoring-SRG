#!/bin/bash

# 🚀 Script Principal de Pruebas de Carga - Validación Métricas Datadog-AWS
# Ejecuta todas las pruebas de carga de manera secuencial y valida métricas

set -euo pipefail

# 🎨 Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 📁 Directorios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTS_DIR="${SCRIPT_DIR}/reports"
LOG_FILE="${REPORTS_DIR}/test-results-$(date +%Y%m%d_%H%M%S).log"
METRICS_FILE="${REPORTS_DIR}/metrics-validation-$(date +%Y%m%d_%H%M%S).json"

# 🔧 Configuración
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
AWS_REGION="us-east-2"
DD_SITE="us5.datadoghq.com"

# ⏱️ Tiempos de prueba (en segundos)
CPU_TEST_DURATION=1200    # 20 minutos
NETWORK_TEST_DURATION=900 # 15 minutos
STORAGE_TEST_DURATION=600 # 10 minutos
MEMORY_TEST_DURATION=720  # 12 minutos
HEALTH_TEST_DURATION=480  # 8 minutos

# 📊 Función de logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${BLUE}[INFO]${NC}  ${timestamp} - $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  ${timestamp} - $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE" ;;
        "TEST") echo -e "${PURPLE}[TEST]${NC} ${timestamp} - $message" | tee -a "$LOG_FILE" ;;
    esac
}

# 🏗️ Función de setup inicial
setup_environment() {
    log "INFO" "🏗️ Configurando entorno de pruebas..."
    
    # Crear directorios necesarios
    mkdir -p "$REPORTS_DIR"
    mkdir -p "${SCRIPT_DIR}/cpu" "${SCRIPT_DIR}/network" "${SCRIPT_DIR}/storage" 
    mkdir -p "${SCRIPT_DIR}/memory" "${SCRIPT_DIR}/alerts"
    
    # Verificar herramientas necesarias
    local tools=("stress-ng" "iperf3" "htop" "curl" "jq" "aws")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "WARN" "Herramientas faltantes: ${missing_tools[*]}"
        log "INFO" "Instalando herramientas faltantes..."
        
        # Instalar herramientas en Amazon Linux 2
        if command -v yum &> /dev/null; then
            sudo yum update -y
            sudo yum install -y stress-ng iperf3 htop jq
        elif command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y stress-ng iperf3 htop jq
        fi
    fi
    
    log "SUCCESS" "Entorno configurado correctamente"
}

# 🔍 Función de pre-validación
pre_validation() {
    log "INFO" "🔍 Ejecutando validaciones previas..."
    
    # Verificar conectividad AWS
    if ! aws sts get-caller-identity &>/dev/null; then
        log "ERROR" "No se puede conectar a AWS. Verificar credenciales."
        return 1
    fi
    
    # Verificar agente Datadog
    if ! sudo systemctl is-active --quiet datadog-agent; then
        log "WARN" "Agente Datadog no está activo. Intentando iniciar..."
        sudo systemctl start datadog-agent
        sleep 10
    fi
    
    # Verificar estado del agente
    if sudo datadog-agent status &>/dev/null; then
        log "SUCCESS" "Agente Datadog funcionando correctamente"
    else
        log "ERROR" "Problemas con agente Datadog"
        return 1
    fi
    
    # Baseline de métricas inicial
    log "INFO" "Capturando baseline de métricas..."
    capture_baseline_metrics
    
    log "SUCCESS" "Validaciones previas completadas"
}

# 📊 Función para capturar métricas baseline
capture_baseline_metrics() {
    local baseline_file="${REPORTS_DIR}/baseline-metrics.json"
    
    cat > "$baseline_file" << EOF
{
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "instance_id": "$INSTANCE_ID",
    "baseline": {
        "cpu_usage": $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}'),
        "memory_usage": $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}'),
        "disk_usage": $(df -h / | awk 'NR==2{print $5}' | sed 's/%//'),
        "load_average": "$(uptime | awk -F'load average:' '{print $2}')"
    }
}
EOF
    
    log "INFO" "Baseline capturado en: $baseline_file"
}

# 🔥 Prueba de estrés CPU
run_cpu_stress_test() {
    log "TEST" "🔥 Iniciando CPU Stress Test (${CPU_TEST_DURATION}s)"
    
    local cpu_cores=$(nproc)
    local test_phases=(
        "baseline:300:0"      # 5min baseline, 0 cores stress
        "warning:300:1"       # 5min warning, 1 core stress  
        "critical:300:${cpu_cores}" # 5min critical, all cores
        "recovery:300:0"      # 5min recovery, 0 cores stress
    )
    
    for phase in "${test_phases[@]}"; do
        IFS=':' read -r phase_name duration stress_cores <<< "$phase"
        
        log "INFO" "Fase: $phase_name - Duración: ${duration}s - Cores: $stress_cores"
        
        if [ "$stress_cores" -gt 0 ]; then
            # Iniciar stress
            stress-ng --cpu "$stress_cores" --timeout "${duration}s" &
            local stress_pid=$!
            log "INFO" "Stress iniciado con PID: $stress_pid"
            
            # Monitorear durante la fase
            monitor_cpu_phase "$phase_name" "$duration" &
            local monitor_pid=$!
            
            # Esperar completar fase
            wait $stress_pid
            kill $monitor_pid 2>/dev/null || true
        else
            # Fase de baseline/recovery
            log "INFO" "Esperando ${duration}s en fase $phase_name..."
            monitor_cpu_phase "$phase_name" "$duration" &
            local monitor_pid=$!
            sleep "$duration"
            kill $monitor_pid 2>/dev/null || true
        fi
        
        log "SUCCESS" "Fase $phase_name completada"
        sleep 30  # Pausa entre fases
    done
    
    log "SUCCESS" "CPU Stress Test completado"
}

# 📊 Monitor de CPU por fase
monitor_cpu_phase() {
    local phase_name=$1
    local duration=$2
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "{\"timestamp\":\"$timestamp\",\"phase\":\"$phase_name\",\"cpu_usage\":$cpu_usage}" >> "${REPORTS_DIR}/cpu-metrics.jsonl"
        
        sleep 10
    done
}

# 🌐 Prueba de carga de red
run_network_load_test() {
    log "TEST" "🌐 Iniciando Network Load Test (${NETWORK_TEST_DURATION}s)"
    
    # Servidor iperf3 temporal
    iperf3 -s -D -p 5201 &
    local iperf_server_pid=$!
    
    sleep 5
    
    local phases=(
        "baseline:180"    # 3min baseline
        "high_traffic:420" # 7min high traffic
        "packet_flood:180" # 3min packet flood
        "recovery:120"    # 2min recovery
    )
    
    for phase in "${phases[@]}"; do
        IFS=':' read -r phase_name duration <<< "$phase"
        
        log "INFO" "Fase de red: $phase_name - Duración: ${duration}s"
        
        case $phase_name in
            "baseline"|"recovery")
                # Solo monitoreo
                monitor_network_phase "$phase_name" "$duration"
                ;;
            "high_traffic")
                # Generar tráfico alto con iperf3
                iperf3 -c localhost -p 5201 -t "$duration" -b 50M &
                local traffic_pid=$!
                monitor_network_phase "$phase_name" "$duration"
                wait $traffic_pid 2>/dev/null || true
                ;;
            "packet_flood")
                # Flood de paquetes pequeños
                ping -f -s 1400 8.8.8.8 &
                local ping_pid=$!
                monitor_network_phase "$phase_name" "$duration"
                kill $ping_pid 2>/dev/null || true
                ;;
        esac
        
        log "SUCCESS" "Fase de red $phase_name completada"
        sleep 30
    done
    
    # Limpiar servidor iperf3
    kill $iperf_server_pid 2>/dev/null || true
    
    log "SUCCESS" "Network Load Test completado"
}

# 📊 Monitor de red por fase
monitor_network_phase() {
    local phase_name=$1
    local duration=$2
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Capturar estadísticas de red
        local net_stats=$(cat /proc/net/dev | grep eth0 || cat /proc/net/dev | head -3 | tail -1)
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "{\"timestamp\":\"$timestamp\",\"phase\":\"$phase_name\",\"net_stats\":\"$net_stats\"}" >> "${REPORTS_DIR}/network-metrics.jsonl"
        
        sleep 15
    done
}

# 💾 Prueba de I/O de storage
run_storage_io_test() {
    log "TEST" "💾 Iniciando Storage I/O Test (${STORAGE_TEST_DURATION}s)"
    
    local test_dir="/tmp/storage_test"
    mkdir -p "$test_dir"
    
    local phases=(
        "random_rw:300"    # 5min random read/write
        "sequential:180"   # 3min sequential
        "mixed:120"        # 2min mixed workload
    )
    
    for phase in "${phases[@]}"; do
        IFS=':' read -r phase_name duration <<< "$phase"
        
        log "INFO" "Fase storage: $phase_name - Duración: ${duration}s"
        
        case $phase_name in
            "random_rw")
                # I/O aleatorio
                dd if=/dev/urandom of="$test_dir/random_file" bs=1M count=100 oflag=direct &
                local dd_pid=$!
                monitor_storage_phase "$phase_name" "$duration"
                kill $dd_pid 2>/dev/null || true
                ;;
            "sequential")
                # I/O secuencial
                dd if=/dev/zero of="$test_dir/seq_file" bs=1M count=200 oflag=direct &
                local dd_pid=$!
                monitor_storage_phase "$phase_name" "$duration"
                kill $dd_pid 2>/dev/null || true
                ;;
            "mixed")
                # Workload mixto
                for i in {1..5}; do
                    dd if=/dev/urandom of="$test_dir/file_$i" bs=512K count=50 oflag=direct &
                done
                monitor_storage_phase "$phase_name" "$duration"
                ;;
        esac
        
        log "SUCCESS" "Fase storage $phase_name completada"
        rm -rf "$test_dir"/*
        sleep 30
    done
    
    rm -rf "$test_dir"
    log "SUCCESS" "Storage I/O Test completado"
}

# 📊 Monitor de storage por fase
monitor_storage_phase() {
    local phase_name=$1
    local duration=$2
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Capturar estadísticas I/O
        local io_stats=$(iostat -d 1 1 2>/dev/null | tail -n +4 || echo "iostat not available")
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "{\"timestamp\":\"$timestamp\",\"phase\":\"$phase_name\",\"io_stats\":\"$io_stats\"}" >> "${REPORTS_DIR}/storage-metrics.jsonl"
        
        sleep 20
    done
}

# 🧠 Prueba de estrés de memoria
run_memory_stress_test() {
    log "TEST" "🧠 Iniciando Memory Stress Test (${MEMORY_TEST_DURATION}s)"
    
    local total_mem=$(free -m | awk 'NR==2{print $2}')
    local target_mem=$((total_mem * 80 / 100))  # 80% de la memoria
    
    local phases=(
        "gradual_fill:360:$target_mem"  # 6min llenado gradual
        "memory_leak:240:$target_mem"   # 4min simulación leak
        "cleanup:120:0"                 # 2min limpieza
    )
    
    for phase in "${phases[@]}"; do
        IFS=':' read -r phase_name duration mem_target <<< "$phase"
        
        log "INFO" "Fase memoria: $phase_name - Duración: ${duration}s - Target: ${mem_target}MB"
        
        case $phase_name in
            "gradual_fill"|"memory_leak")
                # Estrés de memoria
                stress-ng --vm 1 --vm-bytes "${mem_target}M" --timeout "${duration}s" &
                local stress_pid=$!
                monitor_memory_phase "$phase_name" "$duration"
                wait $stress_pid 2>/dev/null || true
                ;;
            "cleanup")
                # Limpieza y recovery
                sync
                echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
                monitor_memory_phase "$phase_name" "$duration"
                ;;
        esac
        
        log "SUCCESS" "Fase memoria $phase_name completada"
        sleep 30
    done
    
    log "SUCCESS" "Memory Stress Test completado"
}

# 📊 Monitor de memoria por fase
monitor_memory_phase() {
    local phase_name=$1
    local duration=$2
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        echo "{\"timestamp\":\"$timestamp\",\"phase\":\"$phase_name\",\"memory_usage\":$mem_usage}" >> "${REPORTS_DIR}/memory-metrics.jsonl"
        
        sleep 15
    done
}

# 🔍 Validación de métricas en Datadog
validate_datadog_metrics() {
    log "TEST" "🔍 Validando métricas en Datadog..."
    
    local validation_results=()
    local metrics_to_check=(
        "aws.ec2.cpuutilization"
        "aws.ec2.networkin"
        "aws.ec2.networkout"
        "aws.ec2.ebsreadops"
        "aws.ec2.ebswriteops"
    )
    
    for metric in "${metrics_to_check[@]}"; do
        log "INFO" "Verificando métrica: $metric"
        
        # Verificar en CloudWatch
        local cw_value=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/EC2 \
            --metric-name "${metric#aws.ec2.}" \
            --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
            --start-time "$(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S)" \
            --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
            --period 300 \
            --statistics Average \
            --region "$AWS_REGION" \
            --query 'Datapoints[0].Average' \
            --output text 2>/dev/null || echo "null")
        
        if [ "$cw_value" != "null" ] && [ "$cw_value" != "None" ]; then
            validation_results+=("✅ $metric: CloudWatch OK")
            log "SUCCESS" "Métrica $metric disponible en CloudWatch: $cw_value"
        else
            validation_results+=("❌ $metric: CloudWatch FALLO")
            log "ERROR" "Métrica $metric NO disponible en CloudWatch"
        fi
        
        sleep 2
    done
    
    # Guardar resultados de validación
    {
        echo "{"
        echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
        echo "  \"instance_id\": \"$INSTANCE_ID\","
        echo "  \"validation_results\": ["
        for result in "${validation_results[@]}"; do
            echo "    \"$result\","
        done | sed '$s/,$//'
        echo "  ]"
        echo "}"
    } > "$METRICS_FILE"
    
    log "SUCCESS" "Validación de métricas completada. Resultados en: $METRICS_FILE"
}

# 📋 Generación de reporte final
generate_final_report() {
    log "INFO" "📋 Generando reporte final..."
    
    local report_file="${REPORTS_DIR}/final-report-$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 📊 Reporte Final - Pruebas de Carga Datadog-AWS

## 🎯 Resumen Ejecutivo
- **Fecha**: $(date '+%Y-%m-%d %H:%M:%S')
- **Instancia**: $INSTANCE_ID
- **Región**: $AWS_REGION
- **Duración Total**: $(($(date +%s) - START_TIME)) segundos

## ✅ Pruebas Ejecutadas
- 🔥 CPU Stress Test: ${CPU_TEST_DURATION}s
- 🌐 Network Load Test: ${NETWORK_TEST_DURATION}s  
- 💾 Storage I/O Test: ${STORAGE_TEST_DURATION}s
- 🧠 Memory Stress Test: ${MEMORY_TEST_DURATION}s

## 📊 Archivos Generados
- Logs completos: $LOG_FILE
- Métricas CPU: ${REPORTS_DIR}/cpu-metrics.jsonl
- Métricas Red: ${REPORTS_DIR}/network-metrics.jsonl
- Métricas Storage: ${REPORTS_DIR}/storage-metrics.jsonl
- Métricas Memoria: ${REPORTS_DIR}/memory-metrics.jsonl
- Validación Datadog: $METRICS_FILE

## 🔗 Enlaces Útiles
- Dashboard Datadog: https://app.${DD_SITE}/dashboard/
- Métricas AWS: https://console.aws.amazon.com/cloudwatch/
- Instance AWS: https://console.aws.amazon.com/ec2/v2/home?region=${AWS_REGION}#Instances:instanceId=${INSTANCE_ID}

EOF

    log "SUCCESS" "Reporte final generado: $report_file"
}

# 🧹 Función de limpieza
cleanup() {
    log "INFO" "🧹 Ejecutando limpieza..."
    
    # Matar procesos de stress que puedan quedar
    pkill -f stress-ng 2>/dev/null || true
    pkill -f iperf3 2>/dev/null || true
    pkill -f ping 2>/dev/null || true
    
    # Limpiar archivos temporales
    rm -rf /tmp/storage_test 2>/dev/null || true
    
    # Limpiar cache de memoria
    sync
    echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    
    log "SUCCESS" "Limpieza completada"
}

# 🎯 Función principal
main() {
    local START_TIME=$(date +%s)
    
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                🚀 PRUEBAS DE CARGA DATADOG-AWS 🚀             ║"
    echo "║                                                              ║"
    echo "║  Validación completa de métricas e integración              ║"
    echo "║  Instancia: $INSTANCE_ID                           ║"
    echo "║  Región: $AWS_REGION                                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Trap para limpieza en caso de interrupción
    trap cleanup EXIT INT TERM
    
    # Ejecutar flujo de pruebas
    setup_environment
    pre_validation
    
    log "INFO" "🚀 Iniciando secuencia de pruebas de carga..."
    
    run_cpu_stress_test
    sleep 60  # Pausa entre pruebas principales
    
    run_network_load_test  
    sleep 60
    
    run_storage_io_test
    sleep 60
    
    run_memory_stress_test
    sleep 60
    
    # Esperar propagación de métricas a Datadog
    log "INFO" "⏱️ Esperando 5 minutos para propagación de métricas a Datadog..."
    sleep 300
    
    validate_datadog_metrics
    generate_final_report
    
    local total_time=$(($(date +%s) - START_TIME))
    log "SUCCESS" "🎉 Todas las pruebas completadas exitosamente en ${total_time} segundos"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    ✅ PRUEBAS COMPLETADAS ✅                   ║"
    echo "║                                                              ║"
    echo "║  Revisa los reportes en: $REPORTS_DIR       ║"
    echo "║  Dashboard Datadog: https://app.${DD_SITE}/dashboard/      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 🚀 Ejecutar script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 