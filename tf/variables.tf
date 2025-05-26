# =========================================
# Variables para Configuración Datadog
# =========================================

variable "datadog_api_key" {
  description = "API Key de Datadog para autenticación"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Application Key de Datadog para API calls"
  type        = string
  sensitive   = true
}

variable "datadog_external_id" {
  description = "External ID único para seguridad adicional en la integración AWS-Datadog"
  type        = string
  sensitive   = true
}

variable "environment_name" {
  description = "Nombre del ambiente (production, staging, development)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["production", "staging", "development"], var.environment_name)
    error_message = "El environment_name debe ser: production, staging, o development."
  }
}

# =========================================
# Variables Opcionales para Datadog
# =========================================

variable "datadog_site" {
  description = "Sitio de Datadog (datadoghq.com, datadoghq.eu, etc.)"
  type        = string
  default     = "datadoghq.com"
}

variable "enable_datadog_logs" {
  description = "Habilitar recolección de logs en Datadog"
  type        = bool
  default     = true
}

variable "custom_tags" {
  description = "Tags personalizados para aplicar a todos los recursos"
  type        = map(string)
  default = {
    project = "lti"
    owner   = "devops"
  }
}

# =========================================
# Variables para Fase 3: AWS Integration
# =========================================

variable "enable_datadog_log_forwarder" {
  description = "Habilitar Datadog Log Forwarder Lambda para envío de logs desde CloudWatch"
  type        = bool
  default     = false
}

variable "enable_datadog_logs_metrics" {
  description = "Habilitar métricas personalizadas desde logs en Datadog"
  type        = bool
  default     = true
}

variable "enable_resource_collection" {
  description = "Habilitar recolección extendida de recursos AWS"
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Días de retención para logs en CloudWatch (para mantener costos bajos)"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_log_retention_days)
    error_message = "Los días de retención deben ser uno de los valores permitidos por CloudWatch."
  }
}

# =========================================
# Variables del Proyecto Existentes
# =========================================

variable "aws_region" {
  description = "Región de AWS para desplegar recursos"
  type        = string
  default     = "us-east-2"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "lti-project"
}

# =========================================
# Variables para Fase 4: Dashboard y Alertas
# =========================================

variable "notification_email" {
  description = "Email para recibir notificaciones de alertas"
  type        = string
  default     = ""
}

variable "slack_webhook_url" {
  description = "Webhook URL de Slack para notificaciones (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_dashboard_auto_refresh" {
  description = "Habilitar auto-refresh automático en dashboard (30 segundos)"
  type        = bool
  default     = true
}

variable "dashboard_time_range" {
  description = "Rango de tiempo por defecto para el dashboard (1h, 4h, 1d, etc.)"
  type        = string
  default     = "1h"
}
