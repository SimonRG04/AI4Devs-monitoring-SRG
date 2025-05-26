# =========================================
# Optimización de Costos: Integración Datadog + AWS
# Proyecto LTI - Fase 6 Cost Optimization
# =========================================

# CloudWatch Log Groups con retención optimizada
resource "aws_cloudwatch_log_group" "lti_backend_optimized" {
  name              = "/aws/ec2/lti-backend-optimized"
  retention_in_days = 1  # Mínimo para free tier
  
  tags = {
    Name        = "LTI Backend Logs Optimized"
    Environment = var.environment_name
    Project     = "lti"
    CostCenter  = "monitoring"
  }
}

resource "aws_cloudwatch_log_group" "lti_frontend_optimized" {
  name              = "/aws/ec2/lti-frontend-optimized"
  retention_in_days = 1  # Mínimo para free tier
  
  tags = {
    Name        = "LTI Frontend Logs Optimized"
    Environment = var.environment_name
    Project     = "lti"
    CostCenter  = "monitoring"
  }
}

# Metric Filters optimizados para reducir custom metrics
resource "aws_cloudwatch_log_metric_filter" "error_rate_optimized" {
  name           = "lti-error-rate-optimized"
  log_group_name = aws_cloudwatch_log_group.lti_backend_optimized.name
  pattern        = "[timestamp, request_id, ERROR]"

  metric_transformation {
    name      = "LTI.ErrorRate.Optimized"
    namespace = "LTI/Application"
    value     = "1"
    
    # Reducir dimensiones para minimizar métricas únicas
    default_value = "0"
  }
}

# CloudWatch Dashboard con widgets optimizados
resource "aws_cloudwatch_dashboard" "cost_optimized" {
  dashboard_name = "LTI-Cost-Optimized"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", "i-02fc645e96bc70814"],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "EC2 Metrics - Cost Optimized"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/ec2/lti-backend-optimized' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent Errors - Cost Optimized"
        }
      }
    ]
  })
}

# Configuración de alertas con umbrales optimizados
resource "aws_cloudwatch_metric_alarm" "cost_optimized_cpu" {
  alarm_name          = "lti-high-cpu-cost-optimized"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"  # Más períodos para evitar false positives
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"  # Umbral más alto para reducir alertas
  alarm_description   = "This metric monitors ec2 cpu utilization - cost optimized"
  alarm_actions       = []  # Sin notificaciones para reducir costos

  dimensions = {
    InstanceId = "i-02fc645e96bc70814"
  }

  tags = {
    Name        = "LTI CPU Alarm Cost Optimized"
    Environment = var.environment_name
    Project     = "lti"
    CostCenter  = "monitoring"
  }
}

# Variables para optimización de costos
variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring (costs extra)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch logs retention in days (1 day minimum for cost optimization)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 7
    error_message = "Log retention must be between 1 and 7 days for cost optimization."
  }
}

variable "enable_cost_alerts" {
  description = "Enable cost monitoring alerts"
  type        = bool
  default     = true
}

# Cost monitoring alarm
resource "aws_cloudwatch_metric_alarm" "estimated_charges" {
  count               = var.enable_cost_alerts ? 1 : 0
  alarm_name          = "lti-estimated-charges"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "86400"  # 24 hours
  statistic           = "Maximum"
  threshold           = "5.00"   # Alert if costs exceed $5
  alarm_description   = "This metric monitors estimated charges for LTI project"
  treat_missing_data  = "notBreaching"

  dimensions = {
    Currency = "USD"
  }

  tags = {
    Name        = "LTI Cost Alert"
    Environment = var.environment_name
    Project     = "lti"
    CostCenter  = "monitoring"
  }
}

# Outputs para tracking de costos
output "cost_optimization_summary" {
  description = "Summary of cost optimization measures"
  value = {
    log_retention_days     = var.log_retention_days
    detailed_monitoring    = var.enable_detailed_monitoring
    cost_alerts_enabled    = var.enable_cost_alerts
    estimated_monthly_cost = "$1.00 - $2.00 USD"
    optimization_measures = [
      "Log retention set to minimum (1 day)",
      "Detailed monitoring disabled",
      "Reduced custom metrics",
      "Optimized dashboard widgets",
      "Cost monitoring alerts enabled"
    ]
  }
}

# Local values para cálculos de costo
locals {
  # Estimación de costos mensuales
  estimated_costs = {
    cloudwatch_logs    = 0.50  # ~$0.50/GB ingested
    cloudwatch_metrics = 0.30  # ~$0.30 for standard metrics
    cloudwatch_alarms  = 0.10  # ~$0.10 per alarm
    total_monthly      = 0.90  # Total estimado
  }
  
  # Tags comunes para cost tracking
  cost_tags = {
    CostCenter    = "monitoring"
    Project       = "lti"
    Environment   = var.environment_name
    Optimization  = "enabled"
    BudgetAlert   = "5USD"
  }
} 