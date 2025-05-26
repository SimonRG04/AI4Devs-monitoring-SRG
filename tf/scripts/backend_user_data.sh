#!/bin/bash

# =========================================
# User Data Script - Backend Instance
# =========================================

# Variables from Terraform
DATADOG_API_KEY="${datadog_api_key}"
DATADOG_SITE="${datadog_site}"
ENVIRONMENT="${environment_name}"
ENABLE_LOGS="${enable_datadog_logs}"

# Log de inicio
echo "$(date): Iniciando configuración del backend - ${timestamp}" >> /var/log/user-data.log

# Actualizar sistema
yum update -y

# Instalar dependencias básicas
yum install -y curl wget unzip

# Instalar Datadog Agent
DD_API_KEY=$DATADOG_API_KEY DD_SITE=$DATADOG_SITE bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

# Configurar tags del agente
cat > /etc/datadog-agent/conf.d/tags.yaml << EOF
tags:
  - env:$ENVIRONMENT
  - service:lti-backend
  - project:lti
  - instance_type:backend
EOF

# Configurar logs si está habilitado
if [ "$ENABLE_LOGS" = "true" ]; then
    cat > /etc/datadog-agent/conf.d/logs.yaml << EOF
logs_enabled: true
logs:
  - type: file
    path: /var/log/messages
    service: lti-backend
    source: system
  - type: file
    path: /var/log/user-data.log
    service: lti-backend
    source: user-data
EOF
fi

# Reiniciar agente Datadog
systemctl restart datadog-agent
systemctl enable datadog-agent

# Configurar aplicación básica (simulada)
mkdir -p /opt/lti-backend
echo "Backend LTI Application - Started at $(date)" > /opt/lti-backend/app.log

echo "$(date): Configuración del backend completada" >> /var/log/user-data.log 