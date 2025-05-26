# =========================================
# Datadog AWS Integration - Configuración Automática MEJORADA
# =========================================

# Configurar provider Datadog con URL correcta para US5
provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  # URL corregida para US5 site
  api_url = "https://api.us5.datadoghq.com/"
}

# Obtener información de la cuenta AWS actual
data "aws_caller_identity" "current" {}

# Obtener información de la instancia EC2 actual
data "aws_instances" "lti_instance" {
  filter {
    name   = "tag:Project"
    values = ["lti-project"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running", "stopped"]
  }
}

# =========================================
# AWS Integration en Datadog MEJORADA
# =========================================

# Configurar integración AWS automática en Datadog
resource "datadog_integration_aws_account" "main" {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = "aws"
  
  # Configuración de autenticación usando rol IAM
  auth_config {
    aws_auth_config_role {
      role_name = aws_iam_role.datadog_integration_role.name
    }
  }

  # Configuración de regiones específicas (optimizar costos)
  aws_regions {
    include_only = [var.aws_region]
  }

  # Configuración de recursos mejorada
  resources_config {
    cloud_security_posture_management_collection = false
    extended_collection                          = var.enable_resource_collection
  }

  # Configuración de métricas expandida para mejor cobertura
  metrics_config {
    automute_enabled = true
    collect_cloudwatch_alarms = true  # Habilitado para alarmas
    collect_custom_metrics = true     # Habilitado para métricas personalizadas
    enabled = true
    
    # Namespaces expandidos para mejor cobertura
    namespace_filters {
      include_only = [
        "AWS/EC2",
        "AWS/EBS", 
        "AWS/Logs",
        "AWS/S3",
        "AWS/Lambda",
        "AWS/ApplicationELB",
        "AWS/NetworkELB",
        "AWS/CloudFront",
        "AWS/RDS",
        "AWS/ElastiCache"
      ]
    }
  }

  # Configuración de traces mejorada
  traces_config {
    xray_services {
      include_only = []  # Sin servicios X-Ray específicos por ahora
    }
  }

  # Configuración de logs habilitada (simplificada)
  logs_config {
    lambda_forwarder {
      sources   = ["s3"]
      lambdas   = []
    }
  }

  # Tags para filtrar recursos
  account_tags = [
    "project:lti",
    "environment:${var.environment_name}",
    "monitoring:datadog",
    "region:${var.aws_region}"
  ]
}

# =========================================
# Configuración adicional para logs
# =========================================

# Log Archive mejorado (habilitado condicionalmente)
resource "datadog_logs_archive" "s3_archive" {
  count = var.enable_datadog_log_forwarder ? 1 : 0
  
  name  = "lti-project-logs-archive-${var.environment_name}"
  query = "service:lti-backend OR service:lti-frontend OR source:aws.ec2"
  
  s3_archive {
    bucket     = aws_s3_bucket.code_bucket.bucket
    path       = "datadog-logs/${var.environment_name}/"
    account_id = data.aws_caller_identity.current.account_id
    role_name  = aws_iam_role.datadog_integration_role.name
  }
}

# =========================================
# Configuración de Métricas Personalizadas Mejorada
# =========================================

# Nota: Pipeline de logs se configurará manualmente en Datadog UI
# debido a limitaciones del provider de Terraform

# =========================================
# Configuración de Service Map
# =========================================

# Nota: Service Map se configurará automáticamente cuando se detecten servicios
# con APM habilitado

# =========================================
# Outputs mejorados para validación
# =========================================

output "datadog_integration_external_id" {
  description = "External ID utilizado en la integración Datadog"
  value       = datadog_integration_aws_account.main.auth_config.aws_auth_config_role.external_id
  sensitive   = true
}

output "datadog_integration_account_id" {
  description = "Account ID configurado en la integración"
  value       = datadog_integration_aws_account.main.aws_account_id
}

output "datadog_integration_role_name" {
  description = "Nombre del rol utilizado en la integración"
  value       = datadog_integration_aws_account.main.auth_config.aws_auth_config_role.role_name
}

output "aws_account_id" {
  description = "AWS Account ID actual"
  value       = data.aws_caller_identity.current.account_id
}

output "datadog_api_url" {
  description = "URL de API de Datadog configurada"
  value       = "https://api.us5.datadoghq.com/"
}

output "enabled_namespaces" {
  description = "Namespaces de AWS habilitados en Datadog"
  value       = datadog_integration_aws_account.main.metrics_config.namespace_filters.include_only
}

output "logs_archive_status" {
  description = "Estado del archivo de logs"
  value       = var.enable_datadog_log_forwarder ? "habilitado" : "deshabilitado"
} 