# =========================================
# Instancias EC2 con Agente Datadog
# =========================================

resource "aws_instance" "backend" {
  ami                    = "ami-075d39ebbca89ed55" # Amazon Linux 2 AMI
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  
  # User data con variables Datadog para backend
  user_data = templatefile("scripts/backend_user_data.sh", {
    timestamp             = timestamp()
    datadog_api_key      = var.datadog_api_key
    datadog_site         = var.datadog_site
    environment_name     = var.environment_name
    enable_datadog_logs  = var.enable_datadog_logs
  })
  
  tags = merge(var.custom_tags, {
    Name        = "lti-project-backend"
    Service     = "lti-backend"
    Component   = "backend"
    Environment = var.environment_name
  })
}

resource "aws_instance" "frontend" {
  ami                    = "ami-075d39ebbca89ed55" # Amazon Linux 2 AMI
  instance_type          = "t2.medium"
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  
  # User data con variables Datadog para frontend
  user_data = templatefile("scripts/frontend_user_data.sh", {
    timestamp             = timestamp()
    datadog_api_key      = var.datadog_api_key
    datadog_site         = var.datadog_site
    environment_name     = var.environment_name
    enable_datadog_logs  = var.enable_datadog_logs
  })
  
  tags = merge(var.custom_tags, {
    Name        = "lti-project-frontend"
    Service     = "lti-frontend"
    Component   = "frontend"
    Environment = var.environment_name
  })
}
