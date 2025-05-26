# Prompt 1 para Cursor utilizando Claude 4.0 modo agent y thinking

## 📋 Contexto del Proyecto

**Objetivo**: Extender código Terraform existente para:
- Configurar integración Datadog con AWS
- Instalar agente Datadog en instancias EC2
- Crear dashboard en Datadog para visualizar métricas AWS
- Mantener costos en capa gratuita de AWS

**Infraestructura Base Existente**:
- Instancias EC2 (Frontend y Backend)
- Security Groups
- Roles IAM básicos
- Scripts de user_data

---

Genera en @datadog-aws-prompts-SRG.md los prompts por fases para realizar la integración.

---

A partir de acá utilicé los diferentes prompts generados para hacer el ejercicio muy faseado

---

# 🚀 Prompts para Integración Datadog + AWS - Proyecto LTI

## 📋 Contexto del Proyecto

**Infraestructura Base Existente**:
- ✅ Instancias EC2: `lti-project-backend` (t2.micro) y `lti-project-frontend` (t2.medium)
- ✅ Security Groups configurados
- ✅ Roles IAM básicos con acceso S3
- ✅ Scripts user_data para despliegue automático
- ✅ Bucket S3 para código de aplicación

**Objetivo**: Integrar Datadog manteniendo costos en capa gratuita AWS

---

## 🔧 FASE 1: Configuración IAM para Datadog

### Prompt 1.1: Crear rol IAM para integración Datadog

```
Crea un nuevo archivo `tf/datadog-iam.tf` que contenga:

1. **Rol IAM para Datadog** con trust policy para la cuenta Datadog
2. **Políticas IAM mínimas** necesarias para monitoreo AWS:
   - CloudWatch read access
   - EC2 read access  
   - S3 read access (solo para métricas)
3. **External ID** configurable via variables para seguridad

Requisitos:
- Usar principio de menor privilegio
- Seguir naming convention: `lti-project-datadog-*`
- Documentar cada permiso con comentarios
- Preparar para integración con API key Datadog

Archivos a modificar:
- `tf/datadog-iam.tf` (nuevo)
- `tf/variables.tf` (agregar external_id)
```

### Prompt 1.2: Extender permisos EC2 existentes

```
Modifica el archivo `tf/iam.tf` para agregar permisos CloudWatch a las instancias EC2:

1. **Ampliar rol EC2 existente** `lti-project-ec2-role` con:
   - CloudWatch PutMetricData
   - CloudWatch CreateLogGroup/CreateLogStream
   - CloudWatch PutLogEvents
2. **Mantener políticas existentes** S3
3. **Agregar comentarios** explicando propósito de cada permiso

Base existente a extender:
- Rol: `aws_iam_role.ec2_role`
- Instancias ya configuradas con instance_profile
```

---

## 🔧 FASE 2: Instalación Agente Datadog

### Prompt 2.1: Modificar user_data backend

```
Modifica `tf/scripts/backend_user_data.sh` para instalar agente Datadog:

1. **Agregar instalación Datadog Agent** después de Docker:
   - Descargar script oficial Datadog
   - Instalar con API key desde variables Terraform
   - Configurar tags: environment, service, version
2. **Configurar métricas personalizadas**:
   - Docker container metrics
   - Application performance metrics
   - Logs collection habilitado
3. **Mantener funcionalidad existente**:
   - No modificar proceso Docker actual
   - Conservar descarga S3 y deploy

Configuración esperada:
- Service: lti-backend
- Environment: production  
- Tags: backend, docker, ec2
```

### Prompt 2.2: Modificar user_data frontend

```
Modifica `tf/scripts/frontend_user_data.sh` para instalar agente Datadog:

1. **Instalación agente Datadog** similar al backend
2. **Tags específicos frontend**:
   - Service: lti-frontend
   - Environment: production
   - Tags: frontend, docker, ec2
3. **Métricas específicas**:
   - Nginx/web server metrics
   - Browser performance (si aplica)
   - User experience metrics

Mantener:
- Proceso de deploy actual intacto
- Configuración Docker existente
```

### Prompt 2.3: Variables Terraform para Datadog

```
Actualiza `tf/variables.tf` para incluir configuración Datadog:

1. **Variables requeridas**:
   - `datadog_api_key` (sensitive)
   - `datadog_app_key` (sensitive)
   - `datadog_external_id` (para rol IAM)
   - `environment_name` (default: "production")
2. **Variables opcionales**:
   - `datadog_site` (default: "datadoghq.com")
   - `enable_datadog_logs` (default: true)
   - `custom_tags` (map, default: {})

Ejemplo valores esperados:
- environment_name = "production"
- custom_tags = { project = "lti", owner = "devops" }
```

---

## 🔧 FASE 3: Integración AWS-Datadog

### Prompt 3.1: Configurar AWS Integration

```
Crea `tf/datadog-aws-integration.tf` para automatizar integración:

1. **Provider Datadog** configurado
2. **AWS Integration** usando rol IAM creado:
   - Account ID automático
   - Role name: rol creado en Fase 1
   - External ID de variables
3. **Filtros de recursos** para costos mínimos:
   - Solo instancias EC2 específicas
   - Solo métricas esenciales CloudWatch
   - Exclusión de servicios no usados

Objetivo: Máximo valor con mínimo costo AWS
```

### Prompt 3.2: Configurar Log Collection

```
Crea configuración para envío de logs desde EC2 a Datadog:

1. **CloudWatch Logs Groups** para cada servicio:
   - `/aws/ec2/lti-backend`
   - `/aws/ec2/lti-frontend`
2. **Log forwarding** usando Datadog Forwarder:
   - Lambda function para forward logs
   - Triggers automáticos CloudWatch
3. **Filtros y parsing**:
   - Docker container logs
   - Application logs
   - System logs básicos

Mantener en free tier: configurar retention mínima
```

---

## 🔧 FASE 4: Dashboard y Alertas

### Prompt 4.1: Dashboard principal LTI Project

```
Crea dashboard Datadog usando Terraform (datadog_dashboard resource):

**Layout sugerido**:
1. **Row 1 - Infrastructure Overview**:
   - EC2 instances status
   - CPU/Memory utilization
   - Network I/O
2. **Row 2 - Application Metrics**:
   - Docker containers status
   - Response times
   - Error rates
3. **Row 3 - Logs & Events**:
   - Recent errors
   - Deployment events
   - System alerts

**Configuración**:
- Template variables: environment, service
- Time range: last 1 hour default
- Auto-refresh: 30 seconds
```

### Prompt 4.2: Alertas básicas de monitoreo

```
Crea alertas Datadog esenciales usando terraform:

1. **Alertas críticas**:
   - EC2 instance down (>5min)
   - High CPU usage (>80% for 10min)
   - High memory usage (>90% for 5min)
   - Application error rate (>5% for 5min)

2. **Alertas de warning**:
   - Disk space low (<10%)
   - Response time high (>2s avg 5min)
   - Docker container restart

3. **Configuración notificaciones**:
   - Email notifications
   - Slack integration (opcional)

Criterio: alertas accionables, evitar false positives
```

---

## 🔧 FASE 5: Testing y Validación

### Prompt 5.1: Script de validación

```
Crea script `scripts/validate-datadog-integration.sh` que verifique:

1. **Conectividad Datadog**:
   - Agent status en ambas instancias
   - API connectivity test
   - Metrics flowing verification

2. **AWS Integration**:
   - CloudWatch metrics disponibles
   - IAM permissions correctos
   - External ID validation

3. **Dashboard y Alertas**:
   - Dashboard carga correctamente
   - Test alerts functional
   - Logs appearing in Datadog

4. **Reporte de salud**:
   - Status summary
   - Troubleshooting hints
   - Cost estimation current usage
```

### Prompt 5.2: Plan de rollback

```
Documenta proceso de rollback en caso de problemas:

1. **Rollback steps**:
   - Desinstalar agente Datadog (command)
   - Revertir user_data scripts
   - Remover recursos Terraform datadog
   - Cleanup IAM policies

2. **Scripts de emergencia**:
   - `rollback-datadog.sh`
   - `restore-original-config.sh`

3. **Validación post-rollback**:
   - Instancias funcionan normal
   - Aplicación accesible
   - No errors en logs

4. **Lecciones aprendidas**:
   - Template para troubleshooting
   - Common issues y soluciones
```

---

## 🔧 FASE 6: Optimización Costos

### Prompt 6.1: Configuración free tier optimizada

```
Revisa y optimiza configuración para mantener costos mínimos:

1. **Métricas limitadas**:
   - Solo custom metrics esenciales
   - Sampling rate apropiado
   - Log retention mínima AWS

2. **Filtros inteligentes**:
   - Exclude noisy metrics
   - Focus en business critical
   - Rate limiting donde posible

3. **Monitoring del gasto**:
   - CloudWatch billing alerts
   - Datadog usage tracking
   - Weekly cost reports

Objetivo: máximo insight, zero additional AWS cost
```

### Prompt 6.2: Documentación final

```
Crea documentación completa del setup:

1. **README-datadog.md** con:
   - Architecture overview
   - Deployment instructions
   - Troubleshooting guide
   - Cost management tips

2. **Runbook operacional**:
   - Daily checks routine
   - Weekly maintenance tasks
   - Monthly cost review
   - Alert response procedures

3. **Terraform documentation**:
   - Variables reference
   - Module dependencies
   - Update procedures
   - Disaster recovery

Target audience: DevOps team y developers
```

---

## ✅ Checklist de Implementación

### Pre-requisitos
- [ ] Cuenta Datadog activa (free trial/plan)
- [ ] API keys Datadog generadas
- [ ] External ID definido para seguridad
- [ ] Backup configuración actual

### Implementación por fases
- [x] **Fase 1**: IAM roles y permisos ✅
- [x] **Fase 2**: Agente en instancias ✅
- [x] **Fase 3**: AWS integration 
- [x] **Fase 4**: Dashboard y alertas 
- [x] **Fase 5**: Testing y validación 
- [x] **Fase 6**: Optimización y docs 

### Post-implementación
- [x] Validación métricas flowing
- [x] Test de alertas funcionando
- [x] Dashboard accesible
- [x] Costos dentro de presupuesto
- [x] Documentación actualizada

---

## 🔍 Métricas Clave a Monitorear

### Infrastructure
- EC2 CPU/Memory/Disk utilization
- Network I/O y latency
- Instance health status

### Application
- Response times backend/frontend
- Error rates y status codes
- Docker container metrics
- Database connections (si aplica)

### Business
- User sessions (si tracking habilitado)
- Feature adoption
- Performance by region

### Cost Management
- AWS CloudWatch costs
- Datadog metric usage
- Log ingestion volume
- Custom metric count

---

# Prompt 2 para cursor utilizando claude 4.0 modo agent y thinking

@tf  
# Análisis y Mejora de Integración Datadog-AWS-Terraform

## Contexto
Revisar la implementación actual de la integración entre Datadog, Terraform y AWS ubicada en el directorio. Adicionalmente es importante tener presente que la instancia del ec2 está en us-east-2 y esta es la url del datadog @https://us5.datadoghq.com/ `.

## Objetivos Principales

### 1. Diagnóstico de Sincronización de Datos
- **Problema identificado**: Los dashboards de Datadog no reflejan correctamente los registros que sí son visibles en CloudWatch
- **Acciones requeridas**:
  - Analizar la configuración actual de la integración AWS-Datadog
  - Comparar los datos disponibles en CloudWatch vs. los mostrados en Datadog
  - Identificar posibles problemas de:
    - Permisos de IAM
    - Configuración de métricas y logs
    - Filtros o transformaciones de datos
    - Latencia en la sincronización

### 2. Mejora de Dashboards
- **Estilos visuales**:
  - Mejorar la legibilidad y organización visual
  - Implementar una paleta de colores consistente
  - Optimizar el layout y distribución de widgets
- **Funcionalidad**:
  - Revisar la configuración de queries y filtros
  - Ajustar períodos de tiempo y agregaciones
  - Validar alertas y umbrales configurados

## Recursos de Referencia
- Documentación oficial de Datadog para integración con AWS
- Documentación de CloudWatch y métricas de AWS
- Configuración actual en Terraform (`)

## Entregables Esperados
1. **Informe de diagnóstico** con causas identificadas de la desincronización
2. **Plan de corrección** con pasos específicos para resolver los problemas
3. **Dashboards actualizados** con mejores estilos y visualización
4. **Documentación** de los cambios implementados y mejores prácticas

## Criterios de Éxito
- Los datos en Datadog coinciden completamente con los disponibles en CloudWatch
- Los dashboards tienen una presentación profesional y clara
- La integración es estable y mantenible a largo plazo.


# Prompt 3 para cursor utilizando claude 4.0 modo agent y thinking

@README.md Revisa el readme para que sea consistente lo que tenemos ahora mismo

# Prompt 4 para cursor utilizando claude 4.0 modo agent y thinking

Excelente, ahora podrías generar un resumen con los desafios que hemos afrontado, que solución se ha propuesto y finalmente lo aprendido de ello.

# Prompt 5 para cursor utilizando claude 4.0 modo agent y thinking

Necesito que generes un conjunto de pruebas de carga para validar las nuevas métricas implementadas en el sistema