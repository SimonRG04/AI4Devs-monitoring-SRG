#!/bin/bash

# =========================================
# User Data Script - Frontend Instance
# =========================================

# Variables from Terraform
DATADOG_API_KEY="${datadog_api_key}"
DATADOG_SITE="${datadog_site}"
ENVIRONMENT="${environment_name}"
ENABLE_LOGS="${enable_datadog_logs}"

# Log de inicio
echo "$(date): Iniciando configuración del frontend - ${timestamp}" >> /var/log/user-data.log

# Actualizar sistema
yum update -y

# Instalar dependencias básicas
yum install -y curl wget unzip httpd

# Instalar Datadog Agent
DD_API_KEY=$DATADOG_API_KEY DD_SITE=$DATADOG_SITE bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

# Configurar tags del agente
cat > /etc/datadog-agent/conf.d/tags.yaml << EOF
tags:
  - env:$ENVIRONMENT
  - service:lti-frontend
  - project:lti
  - instance_type:frontend
EOF

# Configurar logs si está habilitado
if [ "$ENABLE_LOGS" = "true" ]; then
    cat > /etc/datadog-agent/conf.d/logs.yaml << EOF
logs_enabled: true
logs:
  - type: file
    path: /var/log/messages
    service: lti-frontend
    source: system
  - type: file
    path: /var/log/user-data.log
    service: lti-frontend
    source: user-data
  - type: file
    path: /var/log/httpd/access_log
    service: lti-frontend
    source: apache
  - type: file
    path: /var/log/httpd/error_log
    service: lti-frontend
    source: apache
EOF
fi

# Reiniciar agente Datadog
systemctl restart datadog-agent
systemctl enable datadog-agent

# Configurar Apache
systemctl start httpd
systemctl enable httpd

# Crear página básica
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>LTI Project Frontend</title>
</head>
<body>
    <h1>LTI Project Frontend</h1>
    <p>Frontend application started at $(date)</p>
    <p>Environment: $ENVIRONMENT</p>
</body>
</html>
EOF

# Configurar aplicación básica (simulada)
mkdir -p /opt/lti-frontend
echo "Frontend LTI Application - Started at $(date)" > /opt/lti-frontend/app.log

echo "$(date): Configuración del frontend completada" >> /var/log/user-data.log 