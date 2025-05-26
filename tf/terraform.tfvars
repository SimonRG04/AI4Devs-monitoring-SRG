# =========================================
# Archivo de Ejemplo para Variables Terraform
# =========================================
# 
# Copia este archivo como terraform.tfvars y completa los valores
# NUNCA commitees terraform.tfvars con valores reales al control de versiones
#

# =========================================
# Variables Requeridas de Datadog
# =========================================

# Obtén tu API Key desde: https://app.datadoghq.com/organization-settings/api-keys
datadog_api_key = "0b057f1e4a99e4aba1d0368254cb74b5"

# Obtén tu App Key desde: https://app.datadoghq.com/organization-settings/application-keys
datadog_app_key = "0107ffa6123704d452f13a5bc76e2be02560e483"

# Genera un External ID único para seguridad (recomendado: UUID)
# Ejemplo: openssl rand -hex 16
datadog_external_id = "263c8c17630943cd8d05970c4bea6fc2"

# =========================================
# Variables del Proyecto
# =========================================

environment_name = "production"
aws_region      = "us-east-2"

# =========================================
# Variables Opcionales
# =========================================

datadog_site = "us5.datadoghq.com"  # Para EU usa "datadoghq.eu"
enable_datadog_logs = true
enable_datadog_log_forwarder = true
enable_datadog_logs_metrics = true
enable_resource_collection = true

# custom_tags = {
#   project     = "lti"
#   owner       = "devops"
#   environment = "production"
#   cost_center = "engineering"
# } 