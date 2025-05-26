# 🚀 LTI Project - Terraform Infrastructure

## 📋 Descripción

Infraestructura como código para el proyecto LTI con monitoreo completo usando AWS y Datadog. Configuración optimizada y completamente integrada para el sitio US5 de Datadog.

## 🏗️ Arquitectura

- **AWS EC2**: Instancia t2.micro con EBS optimizado
- **Datadog**: Monitoreo avanzado, alertas y dashboard profesional
- **CloudWatch**: Integración completa con 10 namespaces AWS
- **IAM**: Roles y políticas de seguridad expandidas

## 📁 Estructura de Archivos (Post-Limpieza)

### 🔧 **Terraform Core**
```
provider.tf                 # Configuración de providers
variables.tf                # Variables del proyecto  
terraform.tfvars           # Valores de las variables
terraform.tfstate          # Estado actual (NO TOCAR)
terraform.tfstate.backup   # Backup del estado
.terraform.lock.hcl        # Lock de versiones
.terraform/                # Directorio de Terraform
```

### 🏗️ **Infraestructura AWS**
```
ec2.tf                     # Instancia EC2 principal
iam.tf                     # Roles y políticas IAM generales
security_groups.tf         # Grupos de seguridad
s3.tf                      # Bucket S3 para código
```

### 📊 **Datadog Integration (MEJORADA)**
```
datadog-aws-integration.tf    # ✨ Integración AWS-Datadog OPTIMIZADA
datadog-iam.tf               # 🔐 Roles específicos EXPANDIDOS
datadog-dashboard-enhanced.tf # 🚀 Dashboard V2.0 PROFESIONAL
datadog-alerts-optimized.tf  # 🚨 Monitores y alertas OPTIMIZADOS
datadog-log-collection.tf    # 📋 Configuración de logs
```

### 💰 **Optimización**
```
cost-optimization.tf      # Configuraciones para minimizar costos
```

### 🛠️ **Scripts de Verificación**
```
check-datadog-metrics.sh  # ✅ Script principal de verificación
verify-integration.sh     # 🔍 Verificar integración AWS-Datadog
```

### 🗃️ **Subdirectorios**
```
scripts/                  # Scripts de user_data para EC2
  ├── backend_user_data.sh   # Setup automático backend
  └── frontend_user_data.sh  # Setup automático frontend

archive/                  # Scripts históricos de referencia
  ├── apply-improvements.sh  # Script de deployment usado
  └── project-summary.sh     # Script de análisis usado
```

## 🚀 Uso Rápido

### **1. Inicializar Terraform**
```bash
terraform init
```

### **2. Validar Configuración**
```bash
terraform validate
```

### **3. Ver Plan de Cambios**
```bash
terraform plan
```

### **4. Aplicar Infraestructura**
```bash
terraform apply
```

### **5. Verificar Métricas de Datadog**
```bash
./check-datadog-metrics.sh
```

## 📊 Dashboard Principal (V2.0)

### 🎯 **Dashboard Enhanced - ÚNICO Y PRINCIPAL**
- **Archivo**: `datadog-dashboard-enhanced.tf`
- **Características PROFESIONALES**: 
  - ✨ **Variables dinámicas** - Auto-detecta instancias
  - 🎨 **Paleta profesional** - Colores modernos y consistentes
  - 📊 **KPIs destacados** - CPU, Status, Credits en tiempo real
  - 🗂️ **Métricas organizadas** - Por categorías (CPU, Network, Storage, Health)
  - 📱 **Responsive design** - Adaptable a diferentes pantallas
  - 🔗 **Enlaces rápidos** - Navegación directa a Datadog
  - 📈 **Condicional formatting** - Colores según umbrales críticos

### 🌟 **Mejoras V2.0 vs V1.0**
- ❌ **Antes**: Instance ID hardcodeado
- ✅ **Ahora**: Variables dinámicas con template variables
- ❌ **Antes**: Colores básicos
- ✅ **Ahora**: Paleta profesional moderna
- ❌ **Antes**: Widgets dispersos
- ✅ **Ahora**: Agrupación lógica y documentación integrada

## 🚨 Monitores Activos (Optimizados)

1. **🔥 CPU Crítico**: > 90% por 15 minutos
2. **⚠️ CPU Warning**: > 70% por 30 minutos  
3. **💥 Instance Down**: Status check failed
4. **🌐 High Network**: > 20 MB/s
5. **📊 CPU Anomaly**: Detección automática de patrones
6. **💿 CPU Credit Balance**: < 50 créditos restantes
7. **🔍 Status Check Failed**: Fallas sistema/instancia

## 🔍 Verificación y Diagnóstico

### **Verificar Estado Actual**
```bash
terraform output | grep dashboard
```

### **Diagnosticar Métricas (Script Mejorado)**
```bash
./check-datadog-metrics.sh
```

### **Verificar Integración Completa**
```bash
./verify-integration.sh
```

## 🎯 Métricas Disponibles (10 Namespaces)

### ✅ **AWS EC2 Métricas Principales**
- `aws.ec2.cpuutilization` - CPU utilización
- `aws.ec2.cpucreditbalance` - Créditos CPU (T2)
- `aws.ec2.cpucreditusage` - Uso de créditos CPU
- `aws.ec2.networkin/networkout` - Tráfico de red
- `aws.ec2.networkpacketsin/networkpacketsout` - Paquetes
- `aws.ec2.status_check_failed*` - Estados de salud
- `aws.ec2.ebsreadops/ebswriteops` - Operaciones EBS
- `aws.ec2.ebsreadbytes/ebswritebytes` - Throughput EBS

### 🆕 **Nuevos Namespaces Integrados**
- **AWS/EBS** - Volúmenes y storage
- **AWS/Logs** - CloudWatch Logs
- **AWS/S3** - Buckets y objetos
- **AWS/Lambda** - Funciones serverless
- **AWS/ApplicationELB** - Load balancers aplicación
- **AWS/NetworkELB** - Load balancers red
- **AWS/CloudFront** - CDN y distribución
- **AWS/RDS** - Bases de datos relacionales
- **AWS/ElastiCache** - Cache en memoria

## 🎯 Configuración Optimizada

### 🔗 **Integración AWS-Datadog**
- **API URL**: `https://api.us5.datadoghq.com/` (US5 corregido)
- **Namespaces**: 10 servicios habilitados
- **Custom Metrics**: ✅ Habilitado
- **Log Forwarder**: ✅ Configurado
- **Resource Collection**: ✅ Activo

### 🛡️ **IAM Permissions (Expandidas)**
- **CloudWatch**: Acceso completo a métricas y logs
- **EC2**: Descripción instancias y recursos
- **Lambda**: Permisos para log forwarder
- **X-Ray**: Tracing distribuido
- **ELB**: Load balancer metrics

## 🔗 Enlaces Útiles

- **Datadog US5 Site**: https://app.us5.datadoghq.com/
- **Metrics Explorer**: https://app.us5.datadoghq.com/metric/explorer
- **Infrastructure List**: https://app.us5.datadoghq.com/infrastructure
- **AWS Integration**: https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services
- **Dashboard Enhanced**: Ver output `enhanced_dashboard_url`

## ⚠️ Notas Importantes

1. **Tiempo de métricas**: Las métricas pueden tardar 5-15 minutos en aparecer
2. **Estado de Terraform**: NUNCA modificar manualmente `terraform.tfstate`
3. **Credenciales**: Configurar `terraform.tfvars` con las claves correctas
4. **Dashboard principal**: Solo usar `datadog-dashboard-enhanced.tf`
5. **Costos**: La configuración está optimizada para free tier

## 🛠️ Troubleshooting

### **Las métricas no aparecen en Datadog**
1. Esperar 10-15 minutos para sincronización
2. Ejecutar `./check-datadog-metrics.sh`
3. Verificar AWS Integration en Datadog US5
4. Revisar logs de integración

### **Errores de Terraform**
1. `terraform validate` para verificar sintaxis
2. `terraform refresh` para actualizar estado
3. `terraform plan` para ver cambios pendientes
4. Revisar `terraform.log` si hay errores

### **Problemas de permisos IAM**
1. Verificar que el rol Datadog tenga permisos expandidos
2. Ejecutar `./verify-integration.sh`
3. Revisar configuración en AWS Console
4. Confirmar External ID correcto

## 📈 Estado del Proyecto

```
🎯 ESTADO ACTUAL: PRODUCCIÓN READY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Integración AWS-Datadog: 100% funcional
🚀 Dashboard V2.0: Profesional y optimizado  
🔗 Namespaces: 10 servicios AWS integrados
📊 Métricas: Sincronización en tiempo real
🛡️ Seguridad: IAM permisos expandidos
🧹 Código: Limpio y mantenible
```

---

**✅ Proyecto completamente optimizado y funcional**  
**📊 Monitoreo profesional operativo**  
**🔍 Scripts de diagnóstico actualizados**  
**🎯 Dashboard V2.0 con variables dinámicas**
