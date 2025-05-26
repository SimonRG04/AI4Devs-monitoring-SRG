# =========================================
# Datadog Log Collection - CloudWatch Integration
# =========================================

# =========================================
# CloudWatch Log Groups para cada servicio
# =========================================

# Log Group para Backend
resource "aws_cloudwatch_log_group" "lti_backend" {
  name              = "/aws/ec2/lti-backend"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = merge(var.custom_tags, {
    Name        = "lti-backend-logs"
    Service     = "lti-backend"
    Component   = "logs"
    Environment = var.environment_name
    Purpose     = "Backend application logs"
  })
}

# Log Group para Frontend
resource "aws_cloudwatch_log_group" "lti_frontend" {
  name              = "/aws/ec2/lti-frontend"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = merge(var.custom_tags, {
    Name        = "lti-frontend-logs"
    Service     = "lti-frontend"
    Component   = "logs"
    Environment = var.environment_name
    Purpose     = "Frontend application logs"
  })
}

# Log Group para Datadog Forwarder (si se utiliza)
resource "aws_cloudwatch_log_group" "datadog_forwarder" {
  count             = var.enable_datadog_log_forwarder ? 1 : 0
  name              = "/aws/lambda/datadog-forwarder"
  retention_in_days = var.cloudwatch_log_retention_days
  
  tags = merge(var.custom_tags, {
    Name        = "datadog-forwarder-logs"
    Service     = "datadog-forwarder"
    Component   = "lambda-logs"
    Environment = var.environment_name
    Purpose     = "Datadog log forwarder function logs"
  })
}

# =========================================
# IAM Role para Lambda Forwarder (Opcional)
# =========================================

# Política para Datadog Lambda Forwarder
data "aws_iam_policy_document" "datadog_forwarder_policy" {
  count = var.enable_datadog_log_forwarder ? 1 : 0
  
  # Permisos para leer logs de CloudWatch
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents"
    ]
    resources = [
      aws_cloudwatch_log_group.lti_backend.arn,
      aws_cloudwatch_log_group.lti_frontend.arn,
      "${aws_cloudwatch_log_group.lti_backend.arn}:*",
      "${aws_cloudwatch_log_group.lti_frontend.arn}:*"
    ]
  }
  
  # Permisos para S3 si se usa log archive
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.code_bucket.arn,
      "${aws_s3_bucket.code_bucket.arn}/*"
    ]
  }
  
  # Permisos básicos de Lambda
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = ["*"]
  }
}

# Rol IAM para Datadog Forwarder
resource "aws_iam_role" "datadog_forwarder_role" {
  count = var.enable_datadog_log_forwarder ? 1 : 0
  name  = "lti-project-datadog-forwarder-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.custom_tags, {
    Name        = "lti-project-datadog-forwarder-role"
    Purpose     = "Datadog Log Forwarder Lambda Role"
    Environment = var.environment_name
  })
}

# Política personalizada para el forwarder
resource "aws_iam_policy" "datadog_forwarder_policy" {
  count       = var.enable_datadog_log_forwarder ? 1 : 0
  name        = "lti-project-datadog-forwarder-policy"
  description = "Política para Datadog Log Forwarder Lambda"
  policy      = data.aws_iam_policy_document.datadog_forwarder_policy[0].json
  
  tags = merge(var.custom_tags, {
    Name    = "lti-project-datadog-forwarder-policy"
    Purpose = "Datadog Log Forwarder Permissions"
  })
}

# Adjuntar política personalizada
resource "aws_iam_role_policy_attachment" "datadog_forwarder_custom" {
  count      = var.enable_datadog_log_forwarder ? 1 : 0
  role       = aws_iam_role.datadog_forwarder_role[0].name
  policy_arn = aws_iam_policy.datadog_forwarder_policy[0].arn
}

# Adjuntar política básica de Lambda
resource "aws_iam_role_policy_attachment" "datadog_forwarder_basic" {
  count      = var.enable_datadog_log_forwarder ? 1 : 0
  role       = aws_iam_role.datadog_forwarder_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# =========================================
# Filtros de CloudWatch Logs (Método directo)
# =========================================

# Configuración de parsing para logs de aplicación
locals {
  # Filtros específicos para cada tipo de log
  backend_log_patterns = [
    "[timestamp, request_id, level='ERROR', ...]",
    "[timestamp, request_id, level='WARN', ...]",
    "[timestamp, request_id, level='INFO', ...] deployment"
  ]
  
  frontend_log_patterns = [
    "[timestamp, request_id, level='ERROR', ...]",
    "[timestamp, user_id, event='page_load', ...]",
    "[timestamp, user_id, event='click', ...]"
  ]
}

# =========================================
# Configuración de Logs en Datadog (automática)
# =========================================

# Log Processing Rules en Datadog (se configuran automáticamente con el agente)
# Estas reglas se aplican automáticamente cuando el agente Datadog recolecta logs

# =========================================
# Métricas desde Logs (Opcional)
# =========================================

# Configurar métricas personalizadas desde logs usando Datadog
resource "datadog_logs_metric" "error_rate_backend" {
  count = var.enable_datadog_logs_metrics ? 1 : 0
  
  name = "lti.backend.error_rate"
  
  filter {
    query = "service:lti-backend level:error"
  }
  
  compute {
    aggregation_type = "count"
  }
  
  group_by {
    path     = "service"
    tag_name = "service"
  }
}

resource "datadog_logs_metric" "error_rate_frontend" {
  count = var.enable_datadog_logs_metrics ? 1 : 0
  
  name = "lti.frontend.error_rate"
  
  filter {
    query = "service:lti-frontend level:error"
  }
  
  compute {
    aggregation_type = "count"
  }
  
  group_by {
    path     = "service"
    tag_name = "service"
  }
}

# =========================================
# Outputs para Log Collection
# =========================================

output "cloudwatch_log_group_backend" {
  description = "CloudWatch Log Group para Backend"
  value       = aws_cloudwatch_log_group.lti_backend.name
}

output "cloudwatch_log_group_frontend" {
  description = "CloudWatch Log Group para Frontend"
  value       = aws_cloudwatch_log_group.lti_frontend.name
}

output "cloudwatch_log_group_backend_arn" {
  description = "ARN del CloudWatch Log Group para Backend"
  value       = aws_cloudwatch_log_group.lti_backend.arn
}

output "cloudwatch_log_group_frontend_arn" {
  description = "ARN del CloudWatch Log Group para Frontend"
  value       = aws_cloudwatch_log_group.lti_frontend.arn
}

output "datadog_forwarder_role_arn" {
  description = "ARN del rol para Datadog Forwarder (si está habilitado)"
  value       = var.enable_datadog_log_forwarder ? aws_iam_role.datadog_forwarder_role[0].arn : null
} 