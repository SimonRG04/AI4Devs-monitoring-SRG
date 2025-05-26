#!/bin/bash

# =========================================
# VERIFY AWS-DATADOG INTEGRATION - LTI PROJECT
# =========================================

echo "🔍 VERIFICANDO INTEGRACIÓN AWS-DATADOG"
echo "======================================"
echo ""

# Variables críticas
INSTANCE_ID="i-02fc645e96bc70814"
REGION="us-east-2"
ACCOUNT_ID="798831116280"
ROLE_NAME="lti-project-datadog-integration-role"

# Contadores para el resumen final
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# Función para mostrar resultados
check_result() {
    local test_name="$1"
    local result="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$result" = "0" ]; then
        echo "✅ $test_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo "❌ $test_name"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
}

echo "📋 INFORMACIÓN DEL PROYECTO:"
echo "----------------------------"
echo "Instancia EC2: $INSTANCE_ID"
echo "Región AWS: $REGION"
echo "Account ID: $ACCOUNT_ID"
echo "Rol IAM: $ROLE_NAME"
echo ""

echo "🔧 VERIFICACIONES DE TERRAFORM:"
echo "-------------------------------"

# 1. Verificar que Terraform esté inicializado
if [ -f ".terraform.lock.hcl" ] && [ -d ".terraform" ]; then
    check_result "Terraform inicializado" 0
else
    check_result "Terraform inicializado" 1
fi

# 2. Verificar archivos de configuración críticos
critical_files=(
    "datadog-aws-integration.tf"
    "datadog-dashboard-final.tf" 
    "datadog-alerts-optimized.tf"
    "datadog-iam.tf"
    "terraform.tfstate"
)

for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        check_result "Archivo $file existe" 0
    else
        check_result "Archivo $file existe" 1
    fi
done

echo ""
echo "☁️ VERIFICACIONES AWS:"
echo "----------------------"

# 3. Verificar conectividad AWS
if aws sts get-caller-identity --region $REGION &> /dev/null; then
    current_account=$(aws sts get-caller-identity --query 'Account' --output text --region $REGION 2>/dev/null)
    if [ "$current_account" = "$ACCOUNT_ID" ]; then
        check_result "Conectividad AWS (Account correcto)" 0
    else
        check_result "Conectividad AWS (Account: $current_account ≠ $ACCOUNT_ID)" 1
    fi
else
    check_result "Conectividad AWS" 1
fi

# 4. Verificar que la instancia EC2 existe y está corriendo
if aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION &> /dev/null; then
    instance_state=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
    if [ "$instance_state" = "running" ]; then
        check_result "Instancia EC2 ($instance_state)" 0
    else
        check_result "Instancia EC2 ($instance_state)" 1
    fi
else
    check_result "Instancia EC2 existe" 1
fi

# 5. Verificar rol IAM para Datadog
if aws iam get-role --role-name $ROLE_NAME --region $REGION &> /dev/null; then
    check_result "Rol IAM Datadog existe" 0
    
    # Verificar políticas attachadas
    policies=$(aws iam list-attached-role-policies --role-name $ROLE_NAME --region $REGION --query 'AttachedPolicies | length(@)' --output text 2>/dev/null)
    if [ "$policies" -gt "0" ]; then
        check_result "Políticas IAM attachadas ($policies políticas)" 0
    else
        check_result "Políticas IAM attachadas" 1
    fi
else
    check_result "Rol IAM Datadog existe" 1
fi

echo ""
echo "📊 VERIFICACIONES CLOUDWATCH:"
echo "-----------------------------"

# 6. Verificar métricas de CloudWatch
metrics_to_check=(
    "CPUUtilization"
    "NetworkIn"
    "NetworkOut"
    "StatusCheckFailed"
)

for metric in "${metrics_to_check[@]}"; do
    datapoints=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/EC2 \
        --metric-name "$metric" \
        --dimensions Name=InstanceId,Value=$INSTANCE_ID \
        --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 300 \
        --statistics Average \
        --region $REGION \
        --query 'Datapoints | length(@)' \
        --output text 2>/dev/null)
    
    if [ "$datapoints" -gt "0" ]; then
        check_result "Métrica CloudWatch $metric ($datapoints puntos)" 0
    else
        check_result "Métrica CloudWatch $metric" 1
    fi
done

echo ""
echo "🐕 VERIFICACIONES DATADOG:"
echo "-------------------------"

# 7. Verificar conectividad a Datadog
if ping -c 1 app.us5.datadoghq.com &> /dev/null; then
    check_result "Conectividad a Datadog" 0
else
    check_result "Conectividad a Datadog" 1
fi

# 8. Verificar configuración de Terraform para Datadog
if command -v terraform &> /dev/null; then
    # Verificar que los outputs existen
    if terraform output final_dashboard_url &> /dev/null; then
        dashboard_url=$(terraform output -raw final_dashboard_url 2>/dev/null)
        if [[ "$dashboard_url" == *"datadoghq.com"* ]]; then
            check_result "Dashboard Final URL válida" 0
        else
            check_result "Dashboard Final URL válida" 1
        fi
    else
        check_result "Dashboard Final configurado" 1
    fi
    
    if terraform output datadog_integration_account_id &> /dev/null; then
        dd_account=$(terraform output -raw datadog_integration_account_id 2>/dev/null)
        if [ "$dd_account" = "$ACCOUNT_ID" ]; then
            check_result "Account ID en Datadog coincide" 0
        else
            check_result "Account ID en Datadog coincide ($dd_account)" 1
        fi
    else
        check_result "Integración Datadog configurada" 1
    fi
else
    check_result "Terraform disponible" 1
fi

echo ""
echo "🚨 VERIFICACIONES DE MONITORES:"
echo "-------------------------------"

# 9. Verificar que los archivos de alertas no tienen errores de sintaxis
if terraform validate &> /dev/null; then
    check_result "Configuración Terraform válida" 0
else
    check_result "Configuración Terraform válida" 1
fi

echo ""
echo "📈 RESUMEN FINAL:"
echo "=================="
echo "Total verificaciones: $TOTAL_CHECKS"
echo "✅ Exitosas: $PASSED_CHECKS"
echo "❌ Fallidas: $FAILED_CHECKS"

# Calcular porcentaje
if [ $TOTAL_CHECKS -gt 0 ]; then
    percentage=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    echo "📊 Porcentaje de éxito: $percentage%"
else
    percentage=0
fi

echo ""

# Determinar estado general
if [ $percentage -eq 100 ]; then
    echo "🎉 ESTADO: ✅ INTEGRACIÓN COMPLETAMENTE FUNCIONAL"
    echo "   Todos los componentes están operativos."
elif [ $percentage -ge 80 ]; then
    echo "⚠️ ESTADO: 🟡 INTEGRACIÓN MAYORMENTE FUNCIONAL"
    echo "   La mayoría de componentes funcionan, revisar fallos menores."
elif [ $percentage -ge 60 ]; then
    echo "🚨 ESTADO: 🟠 INTEGRACIÓN PARCIALMENTE FUNCIONAL"
    echo "   Algunos componentes críticos pueden fallar."
else
    echo "💥 ESTADO: 🔴 INTEGRACIÓN CON PROBLEMAS CRÍTICOS"
    echo "   Requiere atención inmediata."
fi

echo ""
echo "🔗 RECURSOS ÚTILES:"
echo "------------------"
if [ -f terraform.tfvars ]; then
    echo "• Configuración: terraform.tfvars"
fi
echo "• Dashboard Principal: $(terraform output -raw final_dashboard_url 2>/dev/null || echo 'No disponible')"
echo "• Metrics Explorer: https://app.us5.datadoghq.com/metric/explorer"
echo "• AWS Integration: https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services"

echo ""
echo "🛠️ PRÓXIMOS PASOS:"
echo "------------------"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo "1. 🔍 Revisar elementos marcados con ❌"
    echo "2. 🔧 Corregir configuraciones faltantes"
    echo "3. ⚡ Ejecutar 'terraform plan' y 'terraform apply' si es necesario"
    echo "4. 🔄 Re-ejecutar este script para verificar correcciones"
else
    echo "1. 📊 Visitar dashboard principal para verificar métricas"
    echo "2. ⏰ Esperar 10-15 minutos si las métricas no aparecen"
    echo "3. 🎯 Configurar notificaciones de alertas según necesidades"
fi

echo ""
echo "✅ Verificación completada - $(date '+%Y-%m-%d %H:%M:%S')" 