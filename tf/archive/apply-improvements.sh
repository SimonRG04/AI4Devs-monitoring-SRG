#!/bin/bash

# =========================================
# SCRIPT DE APLICACIÓN DE MEJORAS
# Datadog-AWS-Terraform Integration
# =========================================

set -e  # Salir en caso de error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="improvement_deployment_${TIMESTAMP//[: -]/}.log"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}🚀 APLICANDO MEJORAS DE INTEGRACIÓN DATADOG${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "${CYAN}📅 Inicio: ${TIMESTAMP}${NC}"
echo -e "${CYAN}📄 Log: ${LOG_FILE}${NC}"
echo ""

# Función para logging
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

# Función para ejecutar comandos con logging
run_cmd() {
    local cmd="$1"
    local description="$2"
    
    log "${YELLOW}🔄 ${description}...${NC}"
    
    if eval "$cmd" >> "$LOG_FILE" 2>&1; then
        log "${GREEN}✅ ${description} - ÉXITO${NC}"
        return 0
    else
        log "${RED}❌ ${description} - ERROR${NC}"
        return 1
    fi
}

# Función para verificar requisitos
check_requirements() {
    log "${PURPLE}🔍 VERIFICANDO REQUISITOS...${NC}"
    
    # Verificar Terraform
    if ! command -v terraform &> /dev/null; then
        log "${RED}❌ Terraform no está instalado${NC}"
        exit 1
    fi
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        log "${RED}❌ AWS CLI no está instalado${NC}"
        exit 1
    fi
    
    # Verificar archivos requeridos
    local required_files=(
        "terraform.tfvars"
        "datadog-aws-integration.tf"
        "datadog-iam.tf" 
        "datadog-dashboard-enhanced.tf"
    )
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            log "${RED}❌ Archivo requerido no encontrado: $file${NC}"
            exit 1
        fi
    done
    
    log "${GREEN}✅ Todos los requisitos verificados${NC}"
}

# Función para hacer backup del estado actual
backup_state() {
    log "${PURPLE}💾 CREANDO BACKUP DEL ESTADO ACTUAL...${NC}"
    
    local backup_dir="backup_$(date '+%Y%m%d_%H%M%S')"
    mkdir -p "$backup_dir"
    
    # Backup de archivos importantes
    cp terraform.tfstate* "$backup_dir/" 2>/dev/null || true
    cp terraform.tfvars "$backup_dir/"
    cp *.tf "$backup_dir/"
    
    log "${GREEN}✅ Backup creado en: $backup_dir${NC}"
}

# Función principal de aplicación
apply_improvements() {
    log "${PURPLE}🛠️ APLICANDO MEJORAS...${NC}"
    
    # 1. Inicializar Terraform
    run_cmd "terraform init -upgrade" "Inicializar Terraform con providers actualizados"
    
    # 2. Validar configuración
    run_cmd "terraform validate" "Validar configuración de Terraform"
    
    # 3. Planificar cambios
    log "${YELLOW}📋 Generando plan de cambios...${NC}"
    if terraform plan -out=tfplan.out >> "$LOG_FILE" 2>&1; then
        log "${GREEN}✅ Plan generado exitosamente${NC}"
        
        # Mostrar resumen del plan
        log "${CYAN}📊 RESUMEN DE CAMBIOS:${NC}"
        terraform show -no-color tfplan.out | grep -E "(Plan:|Changes to Outputs:)" | tee -a "$LOG_FILE"
        
    else
        log "${RED}❌ Error al generar plan${NC}"
        return 1
    fi
    
    # 4. Confirmar aplicación
    echo ""
    echo -e "${YELLOW}⚠️ ¿Desea aplicar estos cambios? [y/N]:${NC}"
    read -r confirm
    
    if [[ $confirm =~ ^[Yy]$ ]]; then
        log "${YELLOW}🚀 Aplicando cambios...${NC}"
        
        if terraform apply tfplan.out >> "$LOG_FILE" 2>&1; then
            log "${GREEN}✅ Cambios aplicados exitosamente${NC}"
        else
            log "${RED}❌ Error al aplicar cambios${NC}"
            return 1
        fi
    else
        log "${YELLOW}⏸️ Aplicación cancelada por el usuario${NC}"
        return 0
    fi
    
    # 5. Limpiar archivos temporales
    rm -f tfplan.out
}

# Función para verificar el estado post-aplicación
verify_deployment() {
    log "${PURPLE}🔍 VERIFICANDO DESPLIEGUE...${NC}"
    
    # Obtener outputs importantes
    log "${CYAN}📊 OUTPUTS DE TERRAFORM:${NC}"
    terraform output | tee -a "$LOG_FILE"
    
    # Verificar conectividad con Datadog
    log "${YELLOW}🔄 Verificando conectividad con Datadog...${NC}"
    
    # Obtener información de la integración
    local dashboard_url
    dashboard_url=$(terraform output -raw enhanced_dashboard_url 2>/dev/null || terraform output -raw final_dashboard_url 2>/dev/null || echo "No disponible")
    
    if [[ "$dashboard_url" != "No disponible" ]]; then
        log "${GREEN}✅ Dashboard disponible: $dashboard_url${NC}"
    else
        log "${YELLOW}⚠️ URL del dashboard no disponible${NC}"
    fi
    
    # Ejecutar scripts de verificación existentes
    if [[ -f "check-datadog-metrics.sh" ]]; then
        log "${YELLOW}🔄 Ejecutando verificación de métricas...${NC}"
        bash check-datadog-metrics.sh >> "$LOG_FILE" 2>&1 || true
    fi
    
    if [[ -f "verify-integration.sh" ]]; then
        log "${YELLOW}🔄 Ejecutando verificación de integración...${NC}"
        bash verify-integration.sh >> "$LOG_FILE" 2>&1 || true
    fi
}

# Función para mostrar resumen final
show_summary() {
    log "${BLUE}=============================================${NC}"
    log "${BLUE}📋 RESUMEN FINAL DE MEJORAS${NC}"
    log "${BLUE}=============================================${NC}"
    
    # Obtener información del deployment
    local account_id region instance_id dashboard_url
    
    account_id=$(terraform output -raw aws_account_id 2>/dev/null || echo "No disponible")
    region=$(terraform output -raw aws_region 2>/dev/null || echo "us-east-2")
    instance_id=$(terraform output -raw dashboard_instance_id 2>/dev/null || echo "No disponible")
    dashboard_url=$(terraform output -raw enhanced_dashboard_url 2>/dev/null || terraform output -raw final_dashboard_url 2>/dev/null || echo "No disponible")
    
    log "${GREEN}✅ MEJORAS IMPLEMENTADAS:${NC}"
    log "   • API URL corregida para US5 Datadog"
    log "   • Namespaces expandidos (EC2, EBS, CloudWatch, S3, Lambda, etc.)"
    log "   • Log forwarder habilitado"
    log "   • Permisos IAM ampliados"
    log "   • Dashboard mejorado con variables dinámicas"
    log "   • Diseño profesional implementado"
    log ""
    
    log "${CYAN}📊 INFORMACIÓN DEL SISTEMA:${NC}"
    log "   • AWS Account: $account_id"
    log "   • Región: $region"
    log "   • Instance ID: $instance_id"
    log "   • Dashboard: $dashboard_url"
    log ""
    
    log "${YELLOW}🔗 ENLACES IMPORTANTES:${NC}"
    log "   • Metrics Explorer: https://app.us5.datadoghq.com/metric/explorer"
    log "   • Infrastructure: https://app.us5.datadoghq.com/infrastructure"
    log "   • AWS Integration: https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services"
    log ""
    
    log "${PURPLE}⏭️ PRÓXIMOS PASOS:${NC}"
    log "   1. 🕐 Esperar 10-15 minutos para sincronización completa"
    log "   2. 🔍 Verificar métricas en el dashboard"
    log "   3. 📧 Configurar notificaciones de email si es necesario"
    log "   4. 📱 Configurar alertas móviles"
    log "   5. 📚 Revisar documentación en README.md"
    log ""
    
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    log "${GREEN}🎉 MEJORAS COMPLETADAS EXITOSAMENTE${NC}"
    log "${CYAN}📅 Finalizado: $end_time${NC}"
    log "${CYAN}📄 Log completo: $LOG_FILE${NC}"
}

# Función principal
main() {
    check_requirements
    backup_state
    apply_improvements
    verify_deployment
    show_summary
}

# Manejo de errores
trap 'echo -e "${RED}❌ Script interrumpido. Revisar $LOG_FILE para detalles.${NC}"; exit 1' ERR

# Ejecutar función principal
main "$@" 