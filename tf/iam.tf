# =========================================
# Políticas IAM para Instancias EC2
# =========================================

# Política S3: Permite a las instancias EC2 descargar código desde S3
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.code_bucket.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "s3_access_policy" {
  name   = "s3-access-policy"
  policy = data.aws_iam_policy_document.s3_access_policy.json
  
  tags = {
    Name    = "lti-project-s3-access-policy"
    Purpose = "EC2 S3 Access for Code Deployment"
    Project = "lti-project"
  }
}

# =========================================
# Política CloudWatch: Para métricas y logs del agente Datadog
# =========================================

data "aws_iam_policy_document" "cloudwatch_access_policy" {
  # Permisos para enviar métricas personalizadas a CloudWatch
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }
  
  # Permisos para crear y gestionar log groups/streams
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/lti-*",
      "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/lti-*:*"
    ]
  }
  
  # Permisos adicionales para el agente Datadog
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:DescribeInstances"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_access_policy" {
  name        = "lti-project-cloudwatch-access-policy"
  description = "Política para permitir a las instancias EC2 enviar métricas y logs a CloudWatch para Datadog"
  policy      = data.aws_iam_policy_document.cloudwatch_access_policy.json
  
  tags = {
    Name    = "lti-project-cloudwatch-access-policy"
    Purpose = "EC2 CloudWatch Access for Datadog Agent"
    Project = "lti-project"
  }
}

# =========================================
# Rol IAM para Instancias EC2
# =========================================

# Rol principal para instancias EC2: Permite acceso a S3 y CloudWatch
resource "aws_iam_role" "ec2_role" {
  name               = "lti-project-ec2-role"
  description        = "Rol IAM para instancias EC2 del proyecto LTI con permisos para S3 y CloudWatch"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name    = "lti-project-ec2-role"
    Purpose = "EC2 Role for LTI Project with S3 and CloudWatch access"
    Project = "lti-project"
  }
}

# =========================================
# Adjuntar Políticas al Rol EC2
# =========================================

# Adjuntar política S3 (existente): Para descarga de código de aplicación
resource "aws_iam_role_policy_attachment" "attach_s3_access_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Adjuntar política CloudWatch (nueva): Para envío de métricas y logs del agente Datadog
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_access_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.cloudwatch_access_policy.arn
}

# =========================================
# Instance Profile para EC2
# =========================================

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "lti-project-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
  
  tags = {
    Name    = "lti-project-ec2-instance-profile"
    Purpose = "EC2 Instance Profile for LTI Project"
    Project = "lti-project"
  }
}
