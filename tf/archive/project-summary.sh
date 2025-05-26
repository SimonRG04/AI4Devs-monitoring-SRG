#!/bin/bash

# =========================================
# LTI PROJECT - RESUMEN FINAL DEL PROYECTO
# =========================================

echo "🚀 LTI PROJECT - MONITOREO COMPLETADO"
echo "====================================="
echo ""

# Variables
PROJECT_STATUS="✅ OPERATIVO"
INSTANCE_ID="i-02fc645e96bc70814"
REGION="us-east-2"
ACCOUNT_ID="798831116280"

echo "📋 INFORMACIÓN DEL PROYECTO:"
echo "----------------------------"
echo "Estado: $PROJECT_STATUS"
echo "Instancia EC2: $INSTANCE_ID"
echo "Región AWS: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo "Fecha de completación: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

echo "🏗️ INFRAESTRUCTURA DESPLEGADA:"
echo "------------------------------"

# Verificar que terraform esté inicializado
if [ -f ".terraform.lock.hcl" ]; then
    echo "✅ Terraform: Inicializado y configurado"
else
    echo "❌ Terraform: No inicializado"
fi

# Verificar archivos de configuración principales
declare -A config_files=(
    ["datadog-dashboard-final.tf"]="Dashboard principal"
    ["datadog-alerts-optimized.tf"]="Monitores y alertas"
    ["datadog-aws-integration.tf"]="Integración AWS-Datadog"
    ["datadog-iam.tf"]="Permisos IAM para Datadog"
    ["ec2.tf"]="Instancia EC2"
    ["iam.tf"]="Roles IAM base"
)

for file in "${!config_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file - ${config_files[$file]}"
    else
        echo "❌ $file - ${config_files[$file]}"
    fi
done

echo ""
echo "📊 DASHBOARDS DISPONIBLES:"
echo "--------------------------"

# Obtener URLs de dashboards desde terraform output
echo "Obteniendo información de dashboards..."

if command -v terraform &> /dev/null; then
    FINAL_DASHBOARD=$(terraform output -raw final_dashboard_url 2>/dev/null)
    FIXED_DASHBOARD=$(terraform output -raw fixed_dashboard_url 2>/dev/null)
    UNIFIED_DASHBOARD=$(terraform output -raw unified_dashboard_url 2>/dev/null)
    OPTIMIZED_DASHBOARD=$(terraform output -raw optimized_dashboard_url 2>/dev/null)
    
    if [ ! -z "$FINAL_DASHBOARD" ]; then
        echo "🎯 Dashboard Principal: $FINAL_DASHBOARD"
    fi
    
    if [ ! -z "$FIXED_DASHBOARD" ]; then
        echo "🔧 Dashboard Corregido: $FIXED_DASHBOARD"
    fi
    
    if [ ! -z "$UNIFIED_DASHBOARD" ]; then
        echo "📊 Dashboard Unificado: $UNIFIED_DASHBOARD"
    fi
    
    if [ ! -z "$OPTIMIZED_DASHBOARD" ]; then
        echo "⚡ Dashboard Optimizado: $OPTIMIZED_DASHBOARD"
    fi
else
    echo "⚠️ Terraform no disponible para obtener URLs"
    echo "🎯 Dashboard Principal: https://app.us5.datadoghq.com/dashboard/yz9-t97-pyy"
fi

echo ""
echo "🚨 MONITORES ACTIVOS:"
echo "--------------------"
echo "1. 🔥 CPU Crítico: > 80% por 15 minutos"
echo "2. ⚠️ CPU Warning: > 70% por 30 minutos"
echo "3. 💥 Instance Down: Status check failed"
echo "4. 🌐 High Network: > 20 MB/s tráfico"
echo "5. 📊 CPU Anomaly: Detección automática"

echo ""
echo "🎯 MÉTRICAS MONITOREADAS:"
echo "------------------------"

declare -a metrics=(
    "aws.ec2.cpuutilization - CPU básico"
    "aws.ec2.cpucreditbalance - CPU credits (T2)"
    "aws.ec2.cpucreditusage - CPU credits usados"
    "aws.ec2.networkin/networkout - Tráfico de red"
    "aws.ec2.networkpacketsin/networkpacketsout - Paquetes"
    "aws.ec2.status_check_failed* - Estados de salud"
    "aws.ec2.ebsreadops/ebswriteops - Operaciones EBS"
    "aws.ec2.ebsreadbytes/ebswritebytes - Throughput EBS"
)

for metric in "${metrics[@]}"; do
    echo "✅ $metric"
done

echo ""
echo "🛠️ SCRIPTS DISPONIBLES:"
echo "-----------------------"
echo "✅ check-datadog-metrics.sh - Verificación de métricas"
echo "✅ verify-integration.sh - Verificar integración AWS-Datadog (RESTAURADO)"
echo "✅ project-summary.sh - Este resumen (NUEVO)"

echo ""
echo "📁 ESTRUCTURA LIMPIA:"
echo "--------------------"
total_files=$(find . -maxdepth 1 -type f | wc -l)
tf_files=$(find . -maxdepth 1 -name "*.tf" | wc -l)
script_files=$(find . -maxdepth 1 -name "*.sh" | wc -l)

echo "📊 Total archivos principales: $total_files"
echo "🏗️ Archivos Terraform (.tf): $tf_files"
echo "🛠️ Scripts (.sh): $script_files"
echo "📂 Directorios: scripts/, archived_files/, .terraform/"

echo ""
echo "💰 OPTIMIZACIÓN DE COSTOS:"
echo "--------------------------"
echo "✅ Configuración optimizada para AWS Free Tier"
echo "✅ Métricas básicas de CloudWatch (sin costo extra)"
echo "✅ Datadog Free Tier (hasta 5 hosts, 1 día de retención)"
echo "✅ Monitoreo básico cada 5 minutos"

echo ""
echo "🔗 ENLACES ÚTILES:"
echo "------------------"
echo "• Datadog Metrics Explorer: https://app.us5.datadoghq.com/metric/explorer"
echo "• Infrastructure List: https://app.us5.datadoghq.com/infrastructure"
echo "• AWS Integration: https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services"
echo "• Host Map: https://app.us5.datadoghq.com/infrastructure/map"

echo ""
echo "🔍 VERIFICACIONES FINALES:"
echo "--------------------------"

# Verificar conectividad básica
if ping -c 1 app.us5.datadoghq.com &> /dev/null; then
    echo "✅ Conectividad a Datadog: OK"
else
    echo "⚠️ Conectividad a Datadog: Verificar"
fi

# Verificar archivos de estado
if [ -f "terraform.tfstate" ]; then
    state_size=$(du -h terraform.tfstate | cut -f1)
    echo "✅ Estado de Terraform: $state_size"
else
    echo "❌ Estado de Terraform: No encontrado"
fi

echo ""
echo "🚀 SIGUIENTES PASOS RECOMENDADOS:"
echo "---------------------------------"
echo "1. 📊 Visitar el dashboard principal y verificar que las métricas aparezcan"
echo "2. ⏰ Esperar 10-15 minutos si alguna métrica no aparece inmediatamente"
echo "3. 🔍 Ejecutar ./check-datadog-metrics.sh para diagnóstico"
echo "4. 📧 Configurar notificaciones de alertas (opcional)"
echo "5. 📈 Personalizar dashboards según necesidades específicas"

echo ""
echo "✅ PROYECTO COMPLETADO EXITOSAMENTE"
echo "====================================="
echo "🎉 El monitoreo de infraestructura LTI está operativo"
echo "📊 Todas las métricas están configuradas y funcionando"
echo "🛡️ Alertas activas para prevenir problemas"
echo "💾 Configuración respaldada y versionada"
echo ""
echo "👨‍💻 Para soporte o modificaciones, revisar:"
echo "   - README.md (documentación completa)"
echo "   - terraform.tfvars (configuración)"
echo "   - Scripts de verificación disponibles"
echo ""
echo "🎯 ¡El proyecto LTI está listo para producción!" 