# =========================================
# IAM Role para Integración Datadog
# =========================================

# Política IAM para permitir a Datadog asumir el rol
data "aws_iam_policy_document" "datadog_trust_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"] # Cuenta oficial de Datadog
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.datadog_external_id]
    }
  }
}

# Rol IAM para Datadog
resource "aws_iam_role" "datadog_integration_role" {
  name               = "lti-project-datadog-integration-role"
  assume_role_policy = data.aws_iam_policy_document.datadog_trust_policy.json
  
  tags = {
    Name        = "lti-project-datadog-integration-role"
    Purpose     = "Datadog AWS Integration"
    Environment = var.environment_name
    Project     = "lti-project"
  }
}

# =========================================
# Políticas IAM Mínimas para Datadog
# =========================================

# Política para acceso de lectura a CloudWatch MEJORADA
data "aws_iam_policy_document" "datadog_cloudwatch_policy" {
  # Permisos para leer métricas de CloudWatch
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:List*",
      "cloudwatch:Get*",
      "cloudwatch:Describe*"
    ]
    resources = ["*"]
  }
  
  # Permisos extendidos para leer logs de CloudWatch
  statement {
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "logs:DescribeMetricFilters",
      "logs:GetLogEvents",
      "logs:DescribeSubscriptionFilters"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:*:log-group:*",
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/*",
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/*",
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/s3/*",
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/cloudfront/*"
    ]
  }
  
  # Permisos para alarmas de CloudWatch
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
}

# Política para acceso de lectura a EC2
data "aws_iam_policy_document" "datadog_ec2_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*"
    ]
    resources = ["*"]
  }
  
  # Permisos específicos para tags de instancias
  statement {
    effect = "Allow"
    actions = [
      "tag:GetResources",
      "tag:GetTagKeys",
      "tag:GetTagValues"
    ]
    resources = ["*"]
  }
}

# Política para acceso limitado a S3 (solo métricas)
data "aws_iam_policy_document" "datadog_s3_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:GetBucketNotification",
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
      "s3:ListBucket"
    ]
    resources = ["*"]
  }
  
  # Acceso específico al bucket del proyecto para métricas
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketMetricsConfiguration",
      "s3:GetBucketWebsite"
    ]
    resources = [
      "arn:aws:s3:::ai4devs-project-code-bucket",
      "arn:aws:s3:::ai4devs-project-code-bucket/*"
    ]
  }
}

# Política para acceso a Lambda y otros servicios AWS
data "aws_iam_policy_document" "datadog_lambda_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:List*",
      "lambda:Get*",
      "lambda:DescribeFunction",
      "lambda:ListTags"
    ]
    resources = ["*"]
  }
  
  # Permisos para X-Ray
  statement {
    effect = "Allow"
    actions = [
      "xray:BatchGetTraces",
      "xray:GetServiceGraph",
      "xray:GetTimeSeriesServiceStatistics",
      "xray:GetTraceGraph",
      "xray:GetTraceSummaries"
    ]
    resources = ["*"]
  }
  
  # Permisos para ELB y Application Load Balancer
  statement {
    effect = "Allow"
    actions = [
      "elasticloadbalancing:Describe*"
    ]
    resources = ["*"]
  }
}

# =========================================
# Creación de Políticas IAM
# =========================================

resource "aws_iam_policy" "datadog_cloudwatch_policy" {
  name        = "lti-project-datadog-cloudwatch-policy"
  description = "Política para permitir a Datadog leer métricas de CloudWatch"
  policy      = data.aws_iam_policy_document.datadog_cloudwatch_policy.json
  
  tags = {
    Name    = "lti-project-datadog-cloudwatch-policy"
    Purpose = "Datadog CloudWatch Integration"
    Project = "lti-project"
  }
}

resource "aws_iam_policy" "datadog_ec2_policy" {
  name        = "lti-project-datadog-ec2-policy"
  description = "Política para permitir a Datadog leer información de EC2"
  policy      = data.aws_iam_policy_document.datadog_ec2_policy.json
  
  tags = {
    Name    = "lti-project-datadog-ec2-policy"
    Purpose = "Datadog EC2 Integration"
    Project = "lti-project"
  }
}

resource "aws_iam_policy" "datadog_s3_policy" {
  name        = "lti-project-datadog-s3-policy"
  description = "Política para permitir a Datadog leer métricas básicas de S3"
  policy      = data.aws_iam_policy_document.datadog_s3_policy.json
  
  tags = {
    Name    = "lti-project-datadog-s3-policy"
    Purpose = "Datadog S3 Integration"
    Project = "lti-project"
  }
}

resource "aws_iam_policy" "datadog_lambda_policy" {
  name        = "lti-project-datadog-lambda-policy"
  description = "Política para permitir a Datadog acceder a Lambda y otros servicios AWS"
  policy      = data.aws_iam_policy_document.datadog_lambda_policy.json
  
  tags = {
    Name    = "lti-project-datadog-lambda-policy"
    Purpose = "Datadog Lambda and Services Integration"
    Project = "lti-project"
  }
}

# =========================================
# Adjuntar Políticas al Rol
# =========================================

resource "aws_iam_role_policy_attachment" "datadog_cloudwatch_attachment" {
  role       = aws_iam_role.datadog_integration_role.name
  policy_arn = aws_iam_policy.datadog_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "datadog_ec2_attachment" {
  role       = aws_iam_role.datadog_integration_role.name
  policy_arn = aws_iam_policy.datadog_ec2_policy.arn
}

resource "aws_iam_role_policy_attachment" "datadog_s3_attachment" {
  role       = aws_iam_role.datadog_integration_role.name
  policy_arn = aws_iam_policy.datadog_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "datadog_lambda_attachment" {
  role       = aws_iam_role.datadog_integration_role.name
  policy_arn = aws_iam_policy.datadog_lambda_policy.arn
}

# =========================================
# Outputs para uso en integración
# =========================================

output "datadog_role_arn" {
  description = "ARN del rol IAM para integración con Datadog"
  value       = aws_iam_role.datadog_integration_role.arn
}

output "datadog_role_name" {
  description = "Nombre del rol IAM para integración con Datadog"
  value       = aws_iam_role.datadog_integration_role.name
}

output "datadog_external_id" {
  description = "External ID para seguridad adicional"
  value       = var.datadog_external_id
  sensitive   = true
} 