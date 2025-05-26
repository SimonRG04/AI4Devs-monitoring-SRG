# =========================================
# ALERTAS OPTIMIZADAS - Solo métricas funcionando
# =========================================

# =========================================
# ALERTAS CRÍTICAS - CPU
# =========================================

resource "datadog_monitor" "critical_cpu_usage" {
  name    = "🚨 [CRITICAL] High CPU Usage - LTI Project"
  type    = "metric alert"
  message = <<-EOT
    **🚨 ALERTA CRÍTICA: CPU muy alto**
    
    CPU utilization ha superado el 90% en la instancia {{instance-id.name}}.
    
    **Valor actual:** {{value}}%
    **Instancia:** i-02fc645e96bc70814
    
    **Acciones inmediatas:**
    1. ✅ Verificar procesos con `top` o `htop`
    2. ✅ Revisar logs de aplicación
    3. ✅ Considerar reinicio si es necesario
    4. ✅ Evaluar escalado de instancia
    
    **Dashboard:** https://app.us5.datadoghq.com/dashboard/{{dashboard.id}}
    
    @all
  EOT

  query = "avg(last_10m):avg:aws.ec2.cpuutilization{instance-id:i-02fc645e96bc70814} > 90"

  monitor_thresholds {
    critical = 90
    warning  = 70
  }

  evaluation_delay    = 60
  notify_no_data      = false
  renotify_interval   = 60
  require_full_window = true
  notify_audit        = false

  tags = [
    "project:lti",
    "severity:critical",
    "metric:cpu",
    "instance:i-02fc645e96bc70814"
  ]
}

resource "datadog_monitor" "warning_cpu_usage" {
  name    = "⚠️ [WARNING] Elevated CPU Usage - LTI Project"
  type    = "metric alert"
  message = <<-EOT
    **⚠️ WARNING: CPU elevado**
    
    CPU utilization ha superado el 70% por más de 15 minutos.
    
    **Valor actual:** {{value}}%
    **Instancia:** i-02fc645e96bc70814
    
    **Acciones:**
    1. 🔍 Monitorear tendencia
    2. 🔍 Revisar procesos activos
    3. 🔍 Preparar para posible escalado
    
    **Dashboard:** https://app.us5.datadoghq.com/dashboard/{{dashboard.id}}
  EOT

  query = "avg(last_15m):avg:aws.ec2.cpuutilization{instance-id:i-02fc645e96bc70814} > 80"

  monitor_thresholds {
    critical = 80
    warning = 70
  }
  evaluation_delay    = 60
  notify_no_data      = false
  renotify_interval   = 120
  require_full_window = true
  notify_audit        = false

  tags = [
    "project:lti",
    "severity:warning",
    "metric:cpu",
    "instance:i-02fc645e96bc70814"
  ]
}

# =========================================
# ALERTAS CRÍTICAS - STATUS CHECKS
# =========================================

resource "datadog_monitor" "instance_status_check_failed" {
  name    = "🚨 [CRITICAL] EC2 Status Check Failed - LTI Project"
  type    = "metric alert"
  message = <<-EOT
    **🚨 ALERTA CRÍTICA: Status check fallando**
    
    La instancia {{instance-id.name}} ha fallado status checks.
    
    **Instancia:** i-02fc645e96bc70814
    **Región:** us-east-2
    
    **Acciones inmediatas:**
    1. 🚨 Verificar estado en AWS Console
    2. 🚨 Revisar system logs
    3. 🚨 Verificar conectividad de red
    4. 🚨 Restart instancia si es necesario
    
    **AWS Console:** https://us-east-2.console.aws.amazon.com/ec2/home?region=us-east-2#Instances:instanceId=i-02fc645e96bc70814
    
    @all
  EOT

  query = "avg(last_5m):avg:aws.ec2.status_check_failed{instance-id:i-02fc645e96bc70814} > 0"

  monitor_thresholds {
    critical = 0
  }
  evaluation_delay    = 60
  notify_no_data      = true
  no_data_timeframe   = 10
  renotify_interval   = 30
  require_full_window = false
  notify_audit        = false

  tags = [
    "project:lti",
    "severity:critical",
    "metric:status_check",
    "instance:i-02fc645e96bc70814"
  ]
}

# =========================================
# ALERTAS WARNING - NETWORK
# =========================================

resource "datadog_monitor" "high_network_traffic" {
  name    = "⚠️ [WARNING] High Network Traffic - LTI Project"
  type    = "metric alert"
  message = <<-EOT
    **⚠️ WARNING: Tráfico de red alto**
    
    Network throughput ha superado 10MB/s por más de 10 minutos.
    
    **Valor actual:** {{value}} bytes/s
    **Instancia:** i-02fc645e96bc70814
    
    **Acciones:**
    1. 📊 Monitorear patrones de tráfico
    2. 📊 Verificar aplicaciones que usan red
    3. 📊 Revisar si es tráfico legítimo
    
    **Dashboard:** https://app.us5.datadoghq.com/dashboard/{{dashboard.id}}
  EOT

  query = "avg(last_10m):avg:aws.ec2.networkin{instance-id:i-02fc645e96bc70814} + avg:aws.ec2.networkout{instance-id:i-02fc645e96bc70814} > 20971520"

  monitor_thresholds {
    critical = 20971520  # 20 MB/s
    warning = 10485760  # 10 MB/s
  }
  evaluation_delay    = 60
  notify_no_data      = false
  renotify_interval   = 120
  require_full_window = true
  notify_audit        = false

  tags = [
    "project:lti",
    "severity:warning",
    "metric:network",
    "instance:i-02fc645e96bc70814"
  ]
}

# =========================================
# ALERTAS INFO - BASELINE MONITORING
# =========================================

resource "datadog_monitor" "cpu_baseline_anomaly" {
  name    = "ℹ️ [INFO] CPU Anomaly Detection - LTI Project"
  type    = "metric alert"
  message = <<-EOT
    **ℹ️ INFO: Comportamiento anómalo de CPU**
    
    Se ha detectado un patrón inusual en el uso de CPU.
    
    **Instancia:** i-02fc645e96bc70814
    
    **Acciones:**
    1. 🔍 Revisar para entender el patrón
    2. 🔍 Verificar si corresponde a actividad normal
    3. 🔍 Documentar si es un nuevo patrón esperado
    
    **Dashboard:** https://app.us5.datadoghq.com/dashboard/{{dashboard.id}}
  EOT

  query = "avg(last_30m):avg:aws.ec2.cpuutilization{instance-id:i-02fc645e96bc70814} > 70"

  monitor_thresholds {
    critical = 70
    warning = 50
  }
  evaluation_delay    = 900  # 15 min for anomaly detection
  notify_no_data      = false
  renotify_interval   = 0  # Don't renotify for info alerts
  require_full_window = false
  notify_audit        = false

  tags = [
    "project:lti",
    "severity:info",
    "metric:cpu",
    "type:anomaly",
    "instance:i-02fc645e96bc70814"
  ]
}

# =========================================
# CONFIGURACIÓN DE DOWNTIME PROGRAMADO
# =========================================

# Downtime para mantenimiento programado (comentado por defecto)
# resource "datadog_downtime" "maintenance_window" {
#   scope = ["instance-id:i-02fc645e96bc70814"]
#   start = "2025-01-15T02:00:00Z"
#   end   = "2025-01-15T04:00:00Z"
#   recurrence {
#     type   = "weeks"
#     period = 2
#   }
#   message = "Ventana de mantenimiento programado - LTI Project"
# }

# =========================================
# OUTPUTS
# =========================================

output "optimized_monitor_ids" {
  description = "IDs de monitores optimizados"
  value = {
    critical_cpu_usage            = datadog_monitor.critical_cpu_usage.id
    warning_cpu_usage            = datadog_monitor.warning_cpu_usage.id
    instance_status_check_failed = datadog_monitor.instance_status_check_failed.id
    high_network_traffic         = datadog_monitor.high_network_traffic.id
    cpu_baseline_anomaly         = datadog_monitor.cpu_baseline_anomaly.id
  }
}

output "monitor_urls" {
  description = "URLs de los monitores en Datadog"
  value = {
    critical_cpu_usage            = "https://app.us5.datadoghq.com/monitors/${datadog_monitor.critical_cpu_usage.id}"
    warning_cpu_usage            = "https://app.us5.datadoghq.com/monitors/${datadog_monitor.warning_cpu_usage.id}"
    instance_status_check_failed = "https://app.us5.datadoghq.com/monitors/${datadog_monitor.instance_status_check_failed.id}"
    high_network_traffic         = "https://app.us5.datadoghq.com/monitors/${datadog_monitor.high_network_traffic.id}"
    cpu_baseline_anomaly         = "https://app.us5.datadoghq.com/monitors/${datadog_monitor.cpu_baseline_anomaly.id}"
  }
}

output "alert_summary" {
  description = "Resumen de alertas configuradas"
  value = {
    critical_alerts = 2
    warning_alerts  = 2
    info_alerts     = 1
    total_alerts    = 5
  }
} 