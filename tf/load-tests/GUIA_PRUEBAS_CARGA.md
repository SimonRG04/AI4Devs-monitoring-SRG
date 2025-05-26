# 🚀 Guía Práctica de Pruebas de Carga Datadog-AWS

## 🎯 Objetivo
Validar completamente la integración Datadog-AWS mediante pruebas de carga controladas que generen las métricas configuradas y disparen las alertas establecidas.

---

## ⚡ Inicio Rápido

### **1. Ejecución Completa (Recomendado)**
```bash
cd tf/load-tests/
./run-all-tests.sh
```
**Duración**: ~2 horas  
**Resultado**: Validación completa de todas las métricas

### **2. Validación Rápida**
```bash
./validate-metrics.sh quick
```
**Duración**: ~5 minutos  
**Resultado**: Estado actual del sistema

### **3. Prueba Específica de CPU**
```bash
./cpu/cpu-stress-test.sh progressive 600
```
**Duración**: 10 minutos  
**Resultado**: Validación métricas CPU

### **4. Disparar Alerta Específica**
```bash
./alerts/trigger-alerts.sh cpu_critical
```
**Duración**: 16 minutos  
**Resultado**: Alerta CPU >90% activada

---

## 📊 Scripts Disponibles

### 🏃 **Script Principal**
| Script | Descripción | Duración |
|--------|-------------|----------|
| `run-all-tests.sh` | Ejecuta todas las pruebas secuencialmente | ~2 horas |

### 🔍 **Scripts de Validación**
| Script | Modo | Descripción |
|--------|------|-------------|
| `validate-metrics.sh` | `full` | Validación completa |
| `validate-metrics.sh` | `quick` | Validación rápida |
| `validate-metrics.sh` | `agent` | Solo agente Datadog |
| `validate-metrics.sh` | `cloudwatch` | Solo CloudWatch |
| `validate-metrics.sh` | `sync` | Probar sincronización |

### 🔥 **Scripts de CPU**
| Script | Comando | Descripción |
|--------|---------|-------------|
| `cpu/cpu-stress-test.sh` | `progressive` | Carga progresiva 25→100% |
| `cpu/cpu-stress-test.sh` | `spike` | Picos de 100% CPU |
| `cpu/cpu-stress-test.sh` | `sustained 75 600` | 75% CPU por 10min |
| `cpu/cpu-stress-test.sh` | `stepped` | Escalones controlados |

### 🚨 **Scripts de Alertas**
| Script | Comando | Descripción |
|--------|---------|-------------|
| `alerts/trigger-alerts.sh` | `list` | Ver alertas configuradas |
| `alerts/trigger-alerts.sh` | `cpu_critical` | CPU >90% por 15min |
| `alerts/trigger-alerts.sh` | `cpu_warning` | CPU >70% por 30min |
| `alerts/trigger-alerts.sh` | `network` | Red >20MB/s |
| `alerts/trigger-alerts.sh` | `all` | Todas las alertas |

---

## 🎯 Escenarios de Uso

### **Escenario 1: Primera Validación**
```bash
# 1. Verificar estado inicial
./validate-metrics.sh quick

# 2. Prueba rápida CPU
./cpu/cpu-stress-test.sh sustained 80 300

# 3. Validar que aparecen métricas
./validate-metrics.sh cloudwatch
```

### **Escenario 2: Validación de Alertas**
```bash
# 1. Ver alertas configuradas
./alerts/trigger-alerts.sh list

# 2. Disparar alerta específica
./alerts/trigger-alerts.sh cpu_critical

# 3. Verificar en dashboard Datadog
# URL: https://app.us5.datadoghq.com/monitors/triggered
```

### **Escenario 3: Test de Stress Completo**
```bash
# 1. Prueba progresiva (20 min)
./cpu/cpu-stress-test.sh progressive 1200

# 2. Validar sincronización
./validate-metrics.sh sync

# 3. Análisis de resultados
./cpu/cpu-stress-test.sh analyze
```

### **Escenario 4: Validación Post-Deployment**
```bash
# Después de aplicar terraform apply
./run-all-tests.sh
```

---

## 📈 Métricas Validadas

### ✅ **CPU Metrics**
- `aws.ec2.cpuutilization` - Utilización
- `aws.ec2.cpucreditbalance` - Créditos T2
- `aws.ec2.cpucreditusage` - Uso créditos

### ✅ **Network Metrics**
- `aws.ec2.networkin/networkout` - Tráfico
- `aws.ec2.networkpacketsin/networkpacketsout` - Paquetes

### ✅ **Storage Metrics**
- `aws.ec2.ebsreadops/ebswriteops` - Operaciones
- `aws.ec2.ebsreadbytes/ebswritebytes` - Throughput

### ✅ **Health Metrics**
- `aws.ec2.status_check_failed*` - Estado salud

---

## 🚨 Alertas Configuradas

| Alerta | Umbral | Tiempo | Script |
|--------|---------|--------|---------|
| 🔥 **CPU Critical** | >90% | 15min | `cpu_critical` |
| ⚠️ **CPU Warning** | >70% | 30min | `cpu_warning` |
| 🌐 **High Network** | >20MB/s | 5min | `network` |
| 💿 **CPU Credits** | <50 | 10min | `cpu_credits` |
| 🔍 **Status Check** | Failed | 2min | `status_check` |

---

## 📊 Interpretación de Resultados

### **✅ Éxito Total**
- Todas las métricas aparecen en CloudWatch
- Sincronización <5 minutos a Datadog
- Alertas se disparan según umbrales
- Dashboard funciona correctamente

### **⚠️ Éxito Parcial**
- 80-95% métricas funcionando
- Sincronización 5-10 minutos
- Algunas alertas con demora
- Revisar configuración específica

### **❌ Fallo**
- <80% métricas funcionando
- Sincronización >10 minutos
- Alertas no funcionan
- Revisar integración completa

---

## 🔗 Enlaces Útiles

### **Datadog US5**
- **Dashboard**: https://app.us5.datadoghq.com/dashboard/
- **Metrics Explorer**: https://app.us5.datadoghq.com/metric/explorer
- **Monitors**: https://app.us5.datadoghq.com/monitors/manage
- **Triggered Alerts**: https://app.us5.datadoghq.com/monitors/triggered

### **AWS Console**
- **CloudWatch Metrics**: https://console.aws.amazon.com/cloudwatch/
- **EC2 Instances**: https://console.aws.amazon.com/ec2/
- **Integration Status**: https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services

---

## 🛠️ Troubleshooting

### **Métricas no aparecen**
```bash
# 1. Verificar agente
sudo systemctl status datadog-agent

# 2. Verificar configuración  
sudo datadog-agent configcheck

# 3. Reiniciar si necesario
sudo systemctl restart datadog-agent

# 4. Verificar logs
sudo tail -f /var/log/datadog/agent.log
```

### **Alertas no se disparan**
```bash
# 1. Verificar umbrales alcanzados
./validate-metrics.sh system

# 2. Verificar configuración alertas
./alerts/trigger-alerts.sh list

# 3. Forzar condición específica
./alerts/trigger-alerts.sh cpu_critical
```

### **Pruebas fallan**
```bash
# 1. Limpiar procesos
./alerts/trigger-alerts.sh cleanup

# 2. Verificar recursos
free -h && df -h

# 3. Validar permisos
./validate-metrics.sh agent
```

---

## ⚠️ Consideraciones Importantes

### **🚨 Advertencias**
- Las pruebas pueden afectar el rendimiento temporalmente
- Pueden generar costos adicionales en AWS/Datadog
- Ejecutar en horarios de bajo tráfico
- Tener plan de rollback disponible

### **💰 Costos**
- CloudWatch: Métricas custom y API calls
- Datadog: Métricas adicionales según plan
- EC2: Uso intensivo puede agotar créditos T2
- Red: Transferencia de datos en pruebas

### **⏱️ Tiempos**
- Sincronización inicial: 5-15 minutos
- Propagación alertas: 2-10 minutos  
- Prueba completa: ~2 horas
- Validación básica: ~10 minutos

---

## 🎉 Éxito Esperado

Al completar las pruebas exitosamente tendrás:

✅ **Integración Datadog-AWS 100% funcional**  
✅ **10 namespaces AWS sincronizando métricas**  
✅ **7 alertas configuradas y validadas**  
✅ **Dashboard profesional operativo**  
✅ **Monitoreo proactivo 24/7**  
✅ **Base sólida para escalamiento futuro**

---

**🚀 ¡Comienza con `./run-all-tests.sh` para validación completa o `./validate-metrics.sh quick` para verificación rápida!** 