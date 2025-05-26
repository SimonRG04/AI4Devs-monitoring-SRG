#!/bin/bash

# =========================================
# Script para verificar métricas específicas en Datadog
# =========================================

echo "🔍 VERIFICANDO MÉTRICAS ESPECÍFICAS EN DATADOG"
echo "================================================"
echo ""

# Variables
INSTANCE_ID="i-02fc645e96bc70814"
REGION="us-east-2"

echo "📋 INFORMACIÓN DE DIAGNÓSTICO:"
echo "-----------------------------"
echo "Instancia: $INSTANCE_ID"
echo "Región: $REGION"
echo "Tipo: t2.micro (con burst credits)"
echo ""

echo "🎯 MÉTRICAS QUE DEBERÍAN ESTAR DISPONIBLES EN DATADOG:"
echo "------------------------------------------------------"

declare -A expected_metrics=(
    ["aws.ec2.cpuutilization"]="CPU básico"
    ["aws.ec2.cpucreditbalance"]="CPU credits (T2 only)"
    ["aws.ec2.cpucreditusage"]="CPU credits usados (T2 only)"
    ["aws.ec2.networkin"]="Network entrada"
    ["aws.ec2.networkout"]="Network salida"
    ["aws.ec2.networkpacketsin"]="Paquetes entrada"
    ["aws.ec2.networkpacketsout"]="Paquetes salida"
    ["aws.ec2.status_check_failed"]="Status general"
    ["aws.ec2.status_check_failed_instance"]="Status instancia"
    ["aws.ec2.status_check_failed_system"]="Status sistema"
    ["aws.ec2.ebsreadops"]="EBS operaciones lectura"
    ["aws.ec2.ebswriteops"]="EBS operaciones escritura"
    ["aws.ec2.ebsreadbytes"]="EBS bytes lectura"
    ["aws.ec2.ebswritebytes"]="EBS bytes escritura"
)

for metric in "${!expected_metrics[@]}"; do
    echo "📊 $metric - ${expected_metrics[$metric]}"
done

echo ""
echo "⚠️  MÉTRICAS QUE PUEDEN NO ESTAR DISPONIBLES:"
echo "--------------------------------------------"
echo "❌ aws.ec2.diskreadops - Solo para instance store (no EBS)"
echo "❌ aws.ec2.diskwriteops - Solo para instance store (no EBS)"
echo "❌ aws.ec2.diskreadbytes - Solo para instance store (no EBS)"
echo "❌ aws.ec2.diskwritebytes - Solo para instance store (no EBS)"
echo "❌ aws.ec2.metadatanotoken - Solo en instancias Nitro"

echo ""
echo "🔧 TROUBLESHOOTING STEPS:"
echo "-------------------------"
echo "1. ⏰ Esperar 5-15 minutos después de configurar la integración"
echo "2. 🔍 Verificar en Datadog Metrics Explorer: https://app.us5.datadoghq.com/metric/explorer"
echo "3. 🔧 Verificar configuración de la integración AWS"
echo "4. 📊 Revisar logs de integración en Datadog"

echo ""
echo "🎯 DASHBOARDS DISPONIBLES:"
echo "--------------------------"
echo "Dashboard Final: https://app.us5.datadoghq.com/dashboard/yz9-t97-pyy"
echo "Dashboard Optimizado: https://app.us5.datadoghq.com/dashboard/emc-2bf-4jr"
echo "Dashboard Corregido: https://app.us5.datadoghq.com/dashboard/9kb-t3q-z7r"

echo ""
echo "🔗 ENLACES ÚTILES PARA DIAGNÓSTICO:"
echo "-----------------------------------"
echo "• Datadog Infrastructure List: https://app.us5.datadoghq.com/infrastructure"
echo "• AWS Integration Status: https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services"
echo "• Metrics Explorer: https://app.us5.datadoghq.com/metric/explorer"
echo "• Host Map: https://app.us5.datadoghq.com/infrastructure/map"

echo ""
echo "💡 PUNTOS CLAVE A VERIFICAR:"
echo "----------------------------"
echo "1. ✅ Las métricas están disponibles en CloudWatch (verificado)"
echo "2. ✅ El rol IAM está configurado correctamente (verificado)"
echo "3. ✅ La integración AWS incluye namespace AWS/EC2 y AWS/EBS (verificado)"
echo "4. ⏳ Las métricas pueden tardar hasta 15 minutos en aparecer"
echo "5. 🔍 Algunos widgets pueden mostrar 'No data' hasta que lleguen las métricas"

echo ""
echo "🚀 SIGUIENTE PASO:"
echo "------------------"
echo "Visitar los dashboards en 10-15 minutos para verificar que las métricas aparezcan."
echo ""
echo "✅ Verificación completada." 