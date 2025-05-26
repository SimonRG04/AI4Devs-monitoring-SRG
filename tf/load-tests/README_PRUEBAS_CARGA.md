# 🚀 Pruebas de Carga para Validación de Métricas Datadog-AWS

## 🎯 Objetivo
Validar que todas las métricas implementadas en la integración Datadog-AWS funcionan correctamente bajo diferentes escenarios de carga y que las alertas se disparan según los umbrales configurados.

---

## 📋 Cobertura de Pruebas

### 🔥 **Métricas de CPU**
- `aws.ec2.cpuutilization` - Utilización de CPU
- `aws.ec2.cpucreditbalance` - Balance de créditos CPU (T2)
- `aws.ec2.cpucreditusage` - Uso de créditos CPU

### 🌐 **Métricas de Red**
- `aws.ec2.networkin` - Tráfico de entrada
- `aws.ec2.networkout` - Tráfico de salida
- `aws.ec2.networkpacketsin` - Paquetes de entrada
- `aws.ec2.networkpacketsout` - Paquetes de salida

### 💾 **Métricas de Storage**
- `aws.ec2.ebsreadops` - Operaciones de lectura EBS
- `aws.ec2.ebswriteops` - Operaciones de escritura EBS
- `aws.ec2.ebsreadbytes` - Bytes leídos EBS
- `aws.ec2.ebswritebytes` - Bytes escritos EBS

### 🔍 **Métricas de Estado**
- `aws.ec2.status_check_failed` - Estado de salud general
- `aws.ec2.status_check_failed_instance` - Estado instancia
- `aws.ec2.status_check_failed_system` - Estado sistema

### 💿 **Métricas de Memoria** (via CloudWatch Agent)
- Memory utilization
- Disk space utilization

---

## 🏗️ Estructura de Archivos

```
load-tests/
├── README_PRUEBAS_CARGA.md      # Esta documentación
├── run-all-tests.sh             # Script principal ejecutor
├── validate-metrics.sh          # Validador de métricas
├── cpu/
│   ├── cpu-stress-test.sh       # Prueba de estrés CPU
│   ├── cpu-gradual-load.sh      # Carga gradual CPU
│   └── cpu-spike-test.sh        # Picos de CPU
├── network/
│   ├── network-load-test.sh     # Prueba carga de red
│   ├── bandwidth-test.sh        # Test de ancho de banda
│   └── packet-flood-test.sh     # Test de paquetes
├── storage/
│   ├── disk-io-test.sh          # Prueba I/O disco
│   ├── disk-space-test.sh       # Prueba espacio disco
│   └── ebs-performance-test.sh  # Rendimiento EBS
├── memory/
│   ├── memory-stress-test.sh    # Estrés memoria
│   └── memory-leak-sim.sh       # Simulación memory leak
├── alerts/
│   ├── trigger-alerts.sh        # Disparar todas las alertas
│   └── validate-alerts.sh       # Validar alertas activas
└── reports/
    ├── test-results.log         # Logs de resultados
    └── metrics-validation.json  # Validación métricas
```

---

## 🚀 Ejecución Rápida

### **1. Ejecutar Todas las Pruebas**
```bash
cd load-tests/
chmod +x run-all-tests.sh
./run-all-tests.sh
```

### **2. Pruebas Específicas por Categoría**
```bash
# Solo CPU
./cpu/cpu-stress-test.sh

# Solo Red
./network/network-load-test.sh

# Solo Storage
./storage/disk-io-test.sh

# Disparar alertas específicas
./alerts/trigger-alerts.sh cpu_critical
```

### **3. Validar Métricas en Datadog**
```bash
./validate-metrics.sh
```

---

## 📊 Escenarios de Prueba

### 🔥 **Escenario 1: CPU Stress Test**
**Objetivo**: Validar métricas de CPU y alertas
**Duración**: 20 minutos
**Fases**:
1. **Baseline** (5 min): CPU normal <30%
2. **Warning** (5 min): CPU 70-85% → Alerta Warning
3. **Critical** (5 min): CPU >90% → Alerta Crítica
4. **Recovery** (5 min): Vuelta a baseline

**Métricas validadas**:
- ✅ `aws.ec2.cpuutilization`
- ✅ `aws.ec2.cpucreditusage`
- ✅ `aws.ec2.cpucreditbalance`

**Alertas esperadas**:
- ⚠️ CPU Warning (>70% por 30min)
- 🔥 CPU Critical (>90% por 15min)

### 🌐 **Escenario 2: Network Load Test**
**Objetivo**: Validar métricas de red
**Duración**: 15 minutos
**Fases**:
1. **Baseline** (3 min): Tráfico normal
2. **High Traffic** (7 min): >20 MB/s
3. **Packet Flood** (3 min): Alto volumen paquetes
4. **Recovery** (2 min): Vuelta a normal

**Métricas validadas**:
- ✅ `aws.ec2.networkin/networkout`
- ✅ `aws.ec2.networkpacketsin/networkpacketsout`

**Alertas esperadas**:
- 🌐 High Network Traffic (>20 MB/s)

### 💾 **Escenario 3: Storage I/O Test**
**Objetivo**: Validar métricas de storage
**Duración**: 10 minutos
**Fases**:
1. **Random Read/Write** (5 min)
2. **Sequential I/O** (3 min)
3. **Mixed Workload** (2 min)

**Métricas validadas**:
- ✅ `aws.ec2.ebsreadops/ebswriteops`
- ✅ `aws.ec2.ebsreadbytes/ebswritebytes`

### 🧠 **Escenario 4: Memory Stress Test**
**Objetivo**: Validar métricas de memoria
**Duración**: 12 minutos
**Fases**:
1. **Gradual Fill** (6 min): Llenar memoria gradualmente
2. **Memory Leak Sim** (4 min): Simular memory leak
3. **Cleanup** (2 min): Liberar memoria

**Métricas validadas**:
- ✅ Memory utilization
- ✅ Available memory

### 🔍 **Escenario 5: Health Check Validation**
**Objetivo**: Validar métricas de estado
**Duración**: 8 minutos
**Fases**:
1. **Normal State** (3 min): Todo OK
2. **Simulate Failure** (3 min): Simular fallo
3. **Recovery** (2 min): Recuperación

**Métricas validadas**:
- ✅ `aws.ec2.status_check_failed*`

---

## 📈 Criterios de Éxito

### ✅ **Criterios Técnicos**
1. **Latencia de métricas**: <5 minutos desde generación hasta Datadog
2. **Precisión**: ±5% entre CloudWatch y Datadog
3. **Disponibilidad**: 100% de métricas recibidas
4. **Alertas**: Disparo correcto según umbrales

### ✅ **Criterios de Rendimiento**
1. **CPU Test**: Alcanzar >90% CPU sostenido
2. **Network Test**: Generar >20 MB/s tráfico
3. **Storage Test**: >1000 IOPS sostenidas
4. **Memory Test**: Usar >80% memoria disponible

### ✅ **Criterios de Alertas**
1. **CPU Critical**: Disparo en <2 min cuando CPU >90%
2. **CPU Warning**: Disparo cuando CPU >70% por 30min
3. **Network Alert**: Disparo cuando tráfico >20 MB/s
4. **Instance Down**: Detección inmediata de fallos

---

## 🛠️ Herramientas Utilizadas

### **📊 Generación de Carga**
- `stress-ng`: CPU, memoria y I/O stress
- `iperf3`: Tests de red y ancho de banda
- `dd`: I/O de disco y throughput
- `curl`: Generación tráfico HTTP
- `ping`: Tests de conectividad

### **🔍 Monitoreo y Validación**
- `htop`: Monitor sistema en tiempo real
- `iotop`: Monitor I/O en tiempo real
- `nethogs`: Monitor red por proceso
- `datadog-agent status`: Estado del agente
- `aws cloudwatch get-metric-statistics`: Métricas AWS

### **📋 Logging y Reports**
- `jq`: Procesamiento JSON de métricas
- `curl`: Queries a API Datadog
- `tee`: Logging dual (file + stdout)
- `timestamp`: Timestamping de eventos

---

## ⚠️ Precauciones y Limitaciones

### **🚨 Advertencias**
- **Free Tier**: Estas pruebas pueden exceder límites free tier
- **Costos**: Posible incremento en costos CloudWatch/Datadog
- **Performance**: Impacto temporal en rendimiento de instancia
- **Network**: Consumo de ancho de banda

### **🔒 Medidas de Seguridad**
- **Timeouts**: Todas las pruebas tienen límite de tiempo
- **Cleanup**: Scripts de limpieza automática
- **Monitoring**: Monitoreo continuo durante pruebas
- **Rollback**: Capacidad de parar pruebas inmediatamente

### **📊 Límites Técnicos**
- **t2.micro**: CPU burst limitado por créditos
- **EBS gp2**: IOPS limitadas según tamaño volumen
- **Network**: Ancho banda limitado por tipo instancia
- **Memory**: 1GB RAM total en t2.micro

---

## 📞 Troubleshooting

### **❌ Problemas Comunes**

#### **Métricas no aparecen en Datadog**
```bash
# Verificar agente Datadog
sudo systemctl status datadog-agent
sudo datadog-agent status

# Verificar configuración
sudo datadog-agent configcheck

# Reiniciar agente si necesario
sudo systemctl restart datadog-agent
```

#### **Pruebas fallan por recursos**
```bash
# Verificar recursos disponibles
free -h        # Memoria
df -h          # Disco
htop           # CPU y procesos

# Limpiar recursos
sudo sync && sudo sysctl vm.drop_caches=3
sudo pkill -f stress-ng
```

#### **Alertas no se disparan**
```bash
# Verificar configuración alertas
./validate-metrics.sh alerts

# Verificar umbrales en Datadog
# URL: https://app.us5.datadoghq.com/monitors/manage
```

### **🔧 Comandos de Diagnóstico**
```bash
# Estado general sistema
./load-tests/validate-metrics.sh system

# Verificar conectividad Datadog
curl -X GET "https://api.us5.datadoghq.com/api/v1/validate" \
  -H "DD-API-KEY: ${DD_API_KEY}"

# Logs del agente Datadog
sudo tail -f /var/log/datadog/agent.log

# Métricas en tiempo real
watch -n 2 'aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=$(curl -s http://169.254.169.254/latest/meta-data/instance-id) --start-time $(date -u -d "5 minutes ago" +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average --region us-east-2'
```

---

## 📊 Interpretación de Resultados

### **✅ Éxito Total**
- Todas las métricas aparecen en Datadog
- Alertas se disparan según umbrales
- Latencia <5 minutos
- Precisión ±5%

### **⚠️ Éxito Parcial**
- 80-95% métricas funcionando
- Algunas alertas con demora
- Latencia 5-10 minutos
- Precisión ±10%

### **❌ Fallo**
- <80% métricas funcionando
- Alertas no funcionan
- Latencia >10 minutos
- Precisión >±15%

---

**🎯 Con estas pruebas validaremos completamente la integración Datadog-AWS y aseguraremos que el monitoreo funcione correctamente bajo condiciones reales de carga.** 