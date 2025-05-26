#!/bin/bash

# 🚨 Script para Disparar Alertas Datadog
# Genera condiciones específicas para validar alertas configuradas

set -euo pipefail

# 🎨 Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 🔧 Configuración
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
CPU_CORES=$(nproc)
REPORTS_DIR="$(dirname "$(dirname "$0")")/reports"
DD_SITE="us5.datadoghq.com"

# 📊 Logging
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "INFO")  echo -e "${BLUE}[INFO]${NC}  ${timestamp} - $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC}  ${timestamp} - $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} ${timestamp} - $message" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} ${timestamp} - $message" ;;
        "ALERT") echo -e "${PURPLE}[ALERT]${NC} ${timestamp} - $message" ;;
    esac
}

# 🔥 Disparar alerta CPU Critical (>90% por 15min)
trigger_cpu_critical() {
    log "ALERT" "🔥 Disparando alerta CPU Critical (>90% por 15min)"
    
    mkdir -p "$REPORTS_DIR"
    local alert_log="$REPORTS_DIR/alert-cpu-critical-$(date +%Y%m%d_%H%M%S).jsonl"
    
    log "INFO" "Generando carga 100% CPU por 16 minutos..."
    log "WARN" "Esta alerta debería disparar en ~15 minutos"
    
    # Monitoreo de la alerta
    monitor_alert_trigger "cpu_critical" 960 "$alert_log" &
    local monitor_pid=$!
    
    # Generar carga 100% CPU por 16 minutos
    stress-ng --cpu "$CPU_CORES" --timeout 960s --quiet &
    local stress_pid=$!
    
    log "INFO" "Carga CPU aplicada. Monitoreando alerta..."
    log "INFO" "Verifica dashboard: https://app.$DD_SITE/monitors/manage"
    
    # Esperar completar
    wait $stress_pid 2>/dev/null || true
    kill $monitor_pid 2>/dev/null || true
    
    log "SUCCESS" "Prueba CPU Critical completada. Log: $alert_log"
    log "INFO" "⏱️ Espera 5-10 minutos para que la alerta se active en Datadog"
}

# ⚠️ Disparar alerta CPU Warning (>70% por 30min)
trigger_cpu_warning() {
    log "ALERT" "⚠️ Disparando alerta CPU Warning (>70% por 30min)"
    
    mkdir -p "$REPORTS_DIR"
    local alert_log="$REPORTS_DIR/alert-cpu-warning-$(date +%Y%m%d_%H%M%S).jsonl"
    
    # Calcular cores para ~75% CPU
    local target_cores=$(echo "scale=0; $CPU_CORES * 75 / 100" | bc)
    if [ "$target_cores" -lt 1 ]; then
        target_cores=1
    fi
    
    log "INFO" "Generando carga 75% CPU por 32 minutos..."
    log "INFO" "Usando $target_cores de $CPU_CORES cores"
    log "WARN" "Esta alerta debería disparar en ~30 minutos"
    
    # Monitoreo de la alerta
    monitor_alert_trigger "cpu_warning" 1920 "$alert_log" &
    local monitor_pid=$!
    
    # Generar carga 75% CPU por 32 minutos
    stress-ng --cpu "$target_cores" --timeout 1920s --quiet &
    local stress_pid=$!
    
    log "INFO" "Carga CPU aplicada. Monitoreando alerta..."
    
    # Esperar completar
    wait $stress_pid 2>/dev/null || true
    kill $monitor_pid 2>/dev/null || true
    
    log "SUCCESS" "Prueba CPU Warning completada. Log: $alert_log"
}

# 🌐 Disparar alerta High Network Traffic (>20 MB/s)
trigger_network_alert() {
    log "ALERT" "🌐 Disparando alerta High Network Traffic (>20 MB/s)"
    
    mkdir -p "$REPORTS_DIR"
    local alert_log="$REPORTS_DIR/alert-network-$(date +%Y%m%d_%H%M%S).jsonl"
    
    # Iniciar servidor iperf3
    iperf3 -s -D -p 5201 &
    local server_pid=$!
    sleep 5
    
    log "INFO" "Generando tráfico alto por 10 minutos..."
    
    # Monitoreo de la alerta
    monitor_alert_trigger "network_high" 600 "$alert_log" &
    local monitor_pid=$!
    
    # Generar múltiples conexiones para superar 20 MB/s
    for i in {1..3}; do
        iperf3 -c localhost -p 5201 -t 600 -b 30M &
    done
    
    log "INFO" "Tráfico de red aplicado. Monitoreando alerta..."
    
    # Esperar 10 minutos
    sleep 600
    
    # Limpiar procesos
    kill $monitor_pid 2>/dev/null || true
    kill $server_pid 2>/dev/null || true
    pkill -f iperf3 2>/dev/null || true
    
    log "SUCCESS" "Prueba Network Alert completada. Log: $alert_log"
}

# 💿 Disparar alerta CPU Credit Balance Low (<50 credits)
trigger_cpu_credit_alert() {
    log "ALERT" "💿 Disparando alerta CPU Credit Balance Low (<50 credits)"
    
    # Solo aplicable a instancias T2/T3
    local instance_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null || echo "unknown")
    
    if [[ ! "$instance_type" =~ ^t[23]\. ]]; then
        log "WARN" "Esta alerta solo aplica a instancias T2/T3. Tipo actual: $instance_type"
        return 1
    fi
    
    mkdir -p "$REPORTS_DIR"
    local alert_log="$REPORTS_DIR/alert-cpu-credit-$(date +%Y%m%d_%H%M%S).jsonl"
    
    log "INFO" "Agotando créditos CPU en instancia $instance_type..."
    log "INFO" "Esto puede tomar 30-60 minutos dependiendo del balance inicial"
    
    # Monitoreo de créditos
    monitor_cpu_credits 3600 "$alert_log" &
    local monitor_pid=$!
    
    # Generar carga sostenida para agotar créditos
    stress-ng --cpu "$CPU_CORES" --timeout 3600s --quiet &
    local stress_pid=$!
    
    log "INFO" "Carga aplicada para agotar créditos. Monitoreando..."
    
    # Esperar hasta 1 hora
    wait $stress_pid 2>/dev/null || true
    kill $monitor_pid 2>/dev/null || true
    
    log "SUCCESS" "Prueba CPU Credit completada. Log: $alert_log"
}

# 📊 Monitor genérico de alertas
monitor_alert_trigger() {
    local alert_type=$1
    local duration=$2
    local log_file=$3
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        
        # Log con contexto de alerta
        echo "{\"timestamp\":\"$timestamp\",\"alert_type\":\"$alert_type\",\"cpu_usage\":$cpu_usage,\"memory_usage\":$mem_usage,\"load_avg\":$load_avg,\"instance_id\":\"$INSTANCE_ID\"}" >> "$log_file"
        
        # Mostrar progreso cada 5 minutos
        local elapsed=$(($(date +%s) - (end_time - duration)))
        if [ $((elapsed % 300)) -eq 0 ]; then
            local remaining=$((duration - elapsed))
            log "INFO" "⏱️ Alerta $alert_type - Transcurrido: ${elapsed}s, Restante: ${remaining}s, CPU: ${cpu_usage}%"
        fi
        
        sleep 30
    done
}

# 💿 Monitor específico de créditos CPU
monitor_cpu_credits() {
    local duration=$1
    local log_file=$2
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Obtener créditos CPU de CloudWatch (si está disponible)
        local cpu_credits=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/EC2 \
            --metric-name CPUCreditBalance \
            --dimensions Name=InstanceId,Value="$INSTANCE_ID" \
            --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S)" \
            --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
            --period 300 \
            --statistics Average \
            --region us-east-2 \
            --query 'Datapoints[0].Average' \
            --output text 2>/dev/null || echo "null")
        
        if [ "$cpu_credits" != "null" ] && [ "$cpu_credits" != "None" ]; then
            log "INFO" "💿 Créditos CPU actuales: $cpu_credits"
            
            # Verificar si está por debajo del umbral
            if (( $(echo "$cpu_credits < 50" | bc -l) )); then
                log "ALERT" "🚨 Créditos CPU por debajo del umbral: $cpu_credits < 50"
            fi
        fi
        
        echo "{\"timestamp\":\"$timestamp\",\"alert_type\":\"cpu_credits\",\"cpu_credits\":\"$cpu_credits\",\"instance_id\":\"$INSTANCE_ID\"}" >> "$log_file"
        
        sleep 60  # Check cada minuto
    done
}

# 🔍 Simular fallo de status check
trigger_status_check_alert() {
    log "ALERT" "🔍 Simulando condiciones para Status Check Failed"
    log "WARN" "⚠️ Esta prueba puede afectar temporalmente el rendimiento del sistema"
    
    mkdir -p "$REPORTS_DIR"
    local alert_log="$REPORTS_DIR/alert-status-check-$(date +%Y%m%d_%H%M%S).jsonl"
    
    # Simular alta carga que puede afectar status checks
    log "INFO" "Generando carga extrema para simular fallo de status check..."
    
    # Monitoreo de la alerta
    monitor_alert_trigger "status_check_failed" 600 "$alert_log" &
    local monitor_pid=$!
    
    # Combinación de stress para simular problemas
    stress-ng --cpu "$CPU_CORES" --vm 1 --vm-bytes 80% --timeout 600s --quiet &
    local stress_pid=$!
    
    log "INFO" "Stress aplicado. Monitoreando status checks..."
    
    # Esperar 10 minutos
    wait $stress_pid 2>/dev/null || true
    kill $monitor_pid 2>/dev/null || true
    
    log "SUCCESS" "Prueba Status Check completada. Log: $alert_log"
    log "INFO" "Los status checks pueden tardar 2-5 minutos en reflejarse"
}

# 📊 Mostrar estado de alertas configuradas
show_configured_alerts() {
    log "INFO" "📊 Alertas configuradas en el sistema:"
    
    local alerts=(
        "🔥 CPU Critical: >90% por 15 minutos"
        "⚠️ CPU Warning: >70% por 30 minutos"
        "💥 Instance Down: Status check failed"
        "🌐 High Network: >20 MB/s sostenido"
        "📊 CPU Anomaly: Detección automática ML"
        "💿 CPU Credit: <50 créditos restantes"
        "🔍 Status Check: Sistema/instancia failed"
    )
    
    for alert in "${alerts[@]}"; do
        log "INFO" "  ✅ $alert"
    done
    
    echo
    log "INFO" "🔗 Enlaces útiles:"
    log "INFO" "  Dashboard: https://app.$DD_SITE/dashboard/"
    log "INFO" "  Monitores: https://app.$DD_SITE/monitors/manage"
    log "INFO" "  Alertas: https://app.$DD_SITE/monitors/triggered"
}

# 🎯 Disparar todas las alertas en secuencia
trigger_all_alerts() {
    log "ALERT" "🎯 Iniciando secuencia completa de alertas..."
    log "WARN" "⚠️ Esta secuencia tomará ~2 horas y generará múltiples alertas"
    
    read -p "¿Continuar con todas las alertas? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Secuencia cancelada por el usuario"
        return 0
    fi
    
    # Secuencia de alertas (las más rápidas primero)
    log "INFO" "1/5: Disparando Network Alert (10 min)..."
    trigger_network_alert
    sleep 300  # 5 min pausa
    
    log "INFO" "2/5: Disparando Status Check Alert (10 min)..."
    trigger_status_check_alert
    sleep 300
    
    log "INFO" "3/5: Disparando CPU Critical (16 min)..."
    trigger_cpu_critical
    sleep 300
    
    log "INFO" "4/5: Disparando CPU Warning (32 min)..."
    trigger_cpu_warning
    sleep 300
    
    log "INFO" "5/5: Disparando CPU Credit Alert (hasta 60 min)..."
    trigger_cpu_credit_alert
    
    log "SUCCESS" "🎉 Secuencia completa de alertas finalizada"
}

# 🧹 Limpieza de procesos
cleanup() {
    log "INFO" "🧹 Limpiando procesos de alertas..."
    pkill -f stress-ng 2>/dev/null || true
    pkill -f iperf3 2>/dev/null || true
    log "SUCCESS" "Limpieza completada"
}

# 📚 Ayuda
show_help() {
    echo "🚨 Script para Disparar Alertas Datadog"
    echo
    echo "Uso: $0 [comando]"
    echo
    echo "Comandos disponibles:"
    echo "  cpu_critical     - Disparar alerta CPU >90% (16 min)"
    echo "  cpu_warning      - Disparar alerta CPU >70% (32 min)"
    echo "  network          - Disparar alerta red >20MB/s (10 min)"
    echo "  cpu_credits      - Disparar alerta créditos CPU <50 (60 min)"
    echo "  status_check     - Simular fallo status check (10 min)"
    echo "  all              - Disparar todas las alertas secuencialmente"
    echo "  list             - Mostrar alertas configuradas"
    echo "  cleanup          - Limpiar procesos activos"
    echo
    echo "Ejemplos:"
    echo "  $0 cpu_critical  # Solo alerta CPU crítica"
    echo "  $0 network       # Solo alerta de red"
    echo "  $0 all           # Todas las alertas (2+ horas)"
    echo "  $0 list          # Ver alertas configuradas"
}

# 🎯 Función principal
main() {
    local command="${1:-list}"
    
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               🚨 DISPARADOR DE ALERTAS DATADOG 🚨             ║"
    echo "║                                                              ║"
    echo "║  Validando alertas configuradas mediante carga controlada    ║"
    echo "║  Instancia: $INSTANCE_ID                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Trap para limpieza
    trap cleanup EXIT INT TERM
    
    case $command in
        "cpu_critical")
            trigger_cpu_critical
            ;;
        "cpu_warning")
            trigger_cpu_warning
            ;;
        "network")
            trigger_network_alert
            ;;
        "cpu_credits")
            trigger_cpu_credit_alert
            ;;
        "status_check")
            trigger_status_check_alert
            ;;
        "all")
            trigger_all_alerts
            ;;
        "list")
            show_configured_alerts
            ;;
        "cleanup")
            cleanup
            ;;
        "-h"|"--help"|"help")
            show_help
            exit 0
            ;;
        *)
            log "ERROR" "Comando desconocido: $command"
            show_help
            exit 1
            ;;
    esac
    
    echo
    log "SUCCESS" "🎉 Operación completada"
    log "INFO" "🔗 Verifica las alertas en: https://app.$DD_SITE/monitors/triggered"
}

# 🚀 Ejecutar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 