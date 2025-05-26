#!/bin/bash

# 🔥 Script de Prueba de Estrés CPU
# Genera carga controlada de CPU para validar métricas

set -euo pipefail

# 🎨 Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 🔧 Configuración
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
CPU_CORES=$(nproc)
REPORTS_DIR="$(dirname "$(dirname "$0")")/reports"

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
    esac
}

# 🔥 Prueba de estrés CPU progresiva
progressive_cpu_test() {
    local duration=${1:-300}  # 5 minutos por defecto
    
    log "INFO" "🔥 Iniciando prueba progresiva de CPU (${duration}s total)"
    log "INFO" "Sistema: $CPU_CORES cores disponibles"
    
    mkdir -p "$REPORTS_DIR"
    local cpu_log="$REPORTS_DIR/cpu-progressive-$(date +%Y%m%d_%H%M%S).jsonl"
    
    # Fases progresivas: 25%, 50%, 75%, 100% de cores
    local phases=(
        "light:$((CPU_CORES / 4)):$((duration / 4))"
        "medium:$((CPU_CORES / 2)):$((duration / 4))"
        "heavy:$((CPU_CORES * 3 / 4)):$((duration / 4))"
        "maximum:$CPU_CORES:$((duration / 4))"
    )
    
    for phase in "${phases[@]}"; do
        IFS=':' read -r phase_name cores_used phase_duration <<< "$phase"
        
        # Asegurar mínimo 1 core
        if [ "$cores_used" -lt 1 ]; then
            cores_used=1
        fi
        
        log "INFO" "Fase: $phase_name - Cores: $cores_used/$CPU_CORES - Duración: ${phase_duration}s"
        
        # Iniciar monitoreo en background
        monitor_cpu_usage "$phase_name" "$phase_duration" "$cpu_log" &
        local monitor_pid=$!
        
        # Iniciar stress
        stress-ng --cpu "$cores_used" --timeout "${phase_duration}s" --quiet &
        local stress_pid=$!
        
        # Esperar completar fase
        wait $stress_pid 2>/dev/null || true
        kill $monitor_pid 2>/dev/null || true
        
        log "SUCCESS" "Fase $phase_name completada"
        sleep 30  # Pausa entre fases
    done
    
    log "SUCCESS" "Prueba progresiva completada. Log: $cpu_log"
}

# 📊 Monitor de uso de CPU
monitor_cpu_usage() {
    local phase_name=$1
    local duration=$2
    local log_file=$3
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        # Capturar múltiples métricas de CPU
        local cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/")
        local cpu_usage=$(echo "100 - $cpu_idle" | bc -l 2>/dev/null || echo "0")
        local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Log estructurado
        echo "{\"timestamp\":\"$timestamp\",\"phase\":\"$phase_name\",\"cpu_usage\":$cpu_usage,\"cpu_idle\":$cpu_idle,\"load_avg\":$load_avg,\"instance_id\":\"$INSTANCE_ID\"}" >> "$log_file"
        
        sleep 5
    done
}

# 🎯 Prueba de picos CPU (spike test)
cpu_spike_test() {
    local spike_duration=${1:-60}   # 1 minuto por spike
    local rest_duration=${2:-120}   # 2 minutos de descanso
    local num_spikes=${3:-3}        # 3 spikes
    
    log "INFO" "🎯 Iniciando prueba de picos CPU"
    log "INFO" "Spikes: $num_spikes, Duración: ${spike_duration}s, Descanso: ${rest_duration}s"
    
    mkdir -p "$REPORTS_DIR"
    local spike_log="$REPORTS_DIR/cpu-spikes-$(date +%Y%m%d_%H%M%S).jsonl"
    
    for ((i=1; i<=num_spikes; i++)); do
        log "INFO" "Spike $i/$num_spikes - Carga 100% por ${spike_duration}s"
        
        # Monitoreo durante spike
        monitor_cpu_usage "spike_$i" "$spike_duration" "$spike_log" &
        local monitor_pid=$!
        
        # Spike de CPU al 100%
        stress-ng --cpu "$CPU_CORES" --timeout "${spike_duration}s" --quiet &
        local stress_pid=$!
        
        wait $stress_pid 2>/dev/null || true
        kill $monitor_pid 2>/dev/null || true
        
        log "SUCCESS" "Spike $i completado"
        
        # Periodo de descanso (excepto último spike)
        if [ $i -lt $num_spikes ]; then
            log "INFO" "Descanso por ${rest_duration}s..."
            monitor_cpu_usage "rest_$i" "$rest_duration" "$spike_log" &
            local rest_monitor_pid=$!
            sleep "$rest_duration"
            kill $rest_monitor_pid 2>/dev/null || true
        fi
    done
    
    log "SUCCESS" "Prueba de picos completada. Log: $spike_log"
}

# ⏰ Prueba de duración específica
sustained_cpu_test() {
    local cpu_percentage=${1:-75}   # 75% CPU por defecto
    local duration=${2:-600}        # 10 minutos por defecto
    
    # Calcular cores necesarios para el porcentaje objetivo
    local target_cores=$(echo "scale=0; $CPU_CORES * $cpu_percentage / 100" | bc)
    if [ "$target_cores" -lt 1 ]; then
        target_cores=1
    fi
    
    log "INFO" "⏰ Prueba sostenida: ${cpu_percentage}% CPU por ${duration}s"
    log "INFO" "Usando $target_cores de $CPU_CORES cores"
    
    mkdir -p "$REPORTS_DIR"
    local sustained_log="$REPORTS_DIR/cpu-sustained-$(date +%Y%m%d_%H%M%S).jsonl"
    
    # Monitoreo continuo
    monitor_cpu_usage "sustained_${cpu_percentage}pct" "$duration" "$sustained_log" &
    local monitor_pid=$!
    
    # Carga sostenida
    stress-ng --cpu "$target_cores" --timeout "${duration}s" --quiet &
    local stress_pid=$!
    
    log "INFO" "Carga aplicada. Monitoreando por ${duration}s..."
    
    wait $stress_pid 2>/dev/null || true
    kill $monitor_pid 2>/dev/null || true
    
    log "SUCCESS" "Prueba sostenida completada. Log: $sustained_log"
}

# 🎚️ Prueba de escalones CPU
stepped_cpu_test() {
    local step_duration=${1:-120}  # 2 minutos por paso
    
    log "INFO" "🎚️ Iniciando prueba de escalones CPU"
    
    mkdir -p "$REPORTS_DIR"
    local stepped_log="$REPORTS_DIR/cpu-stepped-$(date +%Y%m%d_%H%M%S).jsonl"
    
    # Escalones: 0%, 25%, 50%, 75%, 100%, 75%, 50%, 25%, 0%
    local steps=(0 25 50 75 100 75 50 25 0)
    
    for step in "${steps[@]}"; do
        local cores_for_step=$(echo "scale=0; $CPU_CORES * $step / 100" | bc)
        
        log "INFO" "Escalón: ${step}% CPU (${cores_for_step} cores) por ${step_duration}s"
        
        if [ "$cores_for_step" -gt 0 ]; then
            # Monitoreo + stress
            monitor_cpu_usage "step_${step}pct" "$step_duration" "$stepped_log" &
            local monitor_pid=$!
            
            stress-ng --cpu "$cores_for_step" --timeout "${step_duration}s" --quiet &
            local stress_pid=$!
            
            wait $stress_pid 2>/dev/null || true
            kill $monitor_pid 2>/dev/null || true
        else
            # Solo monitoreo (0% carga)
            monitor_cpu_usage "baseline" "$step_duration" "$stepped_log" &
            local monitor_pid=$!
            sleep "$step_duration"
            kill $monitor_pid 2>/dev/null || true
        fi
        
        log "SUCCESS" "Escalón ${step}% completado"
    done
    
    log "SUCCESS" "Prueba de escalones completada. Log: $stepped_log"
}

# 📈 Análisis de resultados
analyze_cpu_results() {
    log "INFO" "📈 Analizando resultados de pruebas CPU..."
    
    local latest_log=$(ls -t "$REPORTS_DIR"/cpu-*.jsonl 2>/dev/null | head -1 || echo "")
    
    if [ -z "$latest_log" ]; then
        log "WARN" "No se encontraron logs de pruebas CPU"
        return 1
    fi
    
    log "INFO" "Analizando: $latest_log"
    
    # Estadísticas básicas usando jq si está disponible
    if command -v jq &> /dev/null; then
        local max_cpu=$(jq -r '.cpu_usage' "$latest_log" | sort -n | tail -1)
        local min_cpu=$(jq -r '.cpu_usage' "$latest_log" | sort -n | head -1)
        local avg_cpu=$(jq -r '.cpu_usage' "$latest_log" | awk '{sum+=$1} END {print sum/NR}')
        
        log "INFO" "CPU Max: ${max_cpu}%"
        log "INFO" "CPU Min: ${min_cpu}%"
        log "INFO" "CPU Promedio: ${avg_cpu}%"
    else
        log "INFO" "Instalar 'jq' para análisis detallado"
        log "INFO" "Total de datapoints: $(wc -l < "$latest_log")"
    fi
    
    log "SUCCESS" "Análisis completado"
}

# 🧹 Limpieza
cleanup() {
    log "INFO" "🧹 Limpiando procesos de stress..."
    pkill -f stress-ng 2>/dev/null || true
    log "SUCCESS" "Limpieza completada"
}

# 📚 Ayuda
show_help() {
    echo "🔥 Script de Pruebas de Estrés CPU"
    echo
    echo "Uso: $0 [comando] [parámetros]"
    echo
    echo "Comandos disponibles:"
    echo "  progressive [duration]     - Prueba progresiva (defecto: 300s)"
    echo "  spike [dur] [rest] [num]   - Prueba de picos (defecto: 60s, 120s, 3)"
    echo "  sustained [%] [duration]   - Carga sostenida (defecto: 75%, 600s)"
    echo "  stepped [step_duration]    - Prueba de escalones (defecto: 120s)"
    echo "  analyze                    - Analizar últimos resultados"
    echo "  cleanup                    - Limpiar procesos"
    echo
    echo "Ejemplos:"
    echo "  $0 progressive 600         # Prueba progresiva 10 min"
    echo "  $0 spike 30 60 5          # 5 spikes de 30s con 60s descanso"
    echo "  $0 sustained 90 300       # 90% CPU por 5 min"
    echo "  $0 stepped 180            # Escalones de 3 min cada uno"
}

# 🎯 Función principal
main() {
    local command="${1:-progressive}"
    
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                  🔥 CPU STRESS TEST 🔥                        ║"
    echo "║                                                              ║"
    echo "║  Generando carga controlada para validar métricas           ║"
    echo "║  Instancia: $INSTANCE_ID                           ║"
    echo "║  CPU Cores: $CPU_CORES                                          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Trap para limpieza
    trap cleanup EXIT INT TERM
    
    case $command in
        "progressive")
            progressive_cpu_test "${2:-300}"
            ;;
        "spike")
            cpu_spike_test "${2:-60}" "${3:-120}" "${4:-3}"
            ;;
        "sustained")
            sustained_cpu_test "${2:-75}" "${3:-600}"
            ;;
        "stepped")
            stepped_cpu_test "${2:-120}"
            ;;
        "analyze")
            analyze_cpu_results
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
    
    log "SUCCESS" "🎉 Prueba CPU completada exitosamente"
}

# 🚀 Ejecutar
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 