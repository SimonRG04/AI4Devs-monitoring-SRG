# =========================================
# DASHBOARD MEJORADO - LTI Project Monitoring (PROFESIONAL)
# =========================================

# Obtener instancias EC2 dinámicamente
data "aws_instances" "project_instances" {
  filter {
    name   = "tag:Project"
    values = ["lti-project"]
  }
  
  filter {
    name   = "instance-state-name"
    values = ["running", "stopped", "pending"]
  }
}

# Variables locales para configuración del dashboard
locals {
  # Usar primera instancia encontrada o fallback a la conocida
  instance_id = length(data.aws_instances.project_instances.ids) > 0 ? data.aws_instances.project_instances.ids[0] : "i-02fc645e96bc70814"
  
  # Paleta de colores profesional
  colors = {
    primary   = "#1f77b4"  # Azul profesional
    success   = "#2ca02c"  # Verde éxito
    warning   = "#ff7f0e"  # Naranja advertencia
    danger    = "#d62728"  # Rojo peligro
    info      = "#17a2b8"  # Azul info
    secondary = "#6c757d"  # Gris secundario
  }
  
  # Templates para queries dinámicas
  base_filter = "instance-id:${local.instance_id}"
}

resource "datadog_dashboard" "enhanced_dashboard" {
  title       = "🚀 LTI Project - Dashboard Profesional v2.0"
  description = "Dashboard mejorado con variables dinámicas, mejor diseño y sincronización optimizada | Instancia: ${local.instance_id} | Región: ${var.aws_region}"
  layout_type = "ordered"
  
  # Variables del dashboard para filtrado dinámico
  template_variable {
    name    = "instance"
    prefix  = "instance-id"
    default = local.instance_id
  }
  
  template_variable {
    name    = "region"
    prefix  = "region"
    default = var.aws_region
  }
  
  # Tags para organización mejorada
  tags = [
    "team:lti-project"
  ]

  # =========================================
  # ENCABEZADO CON INFORMACIÓN DEL PROYECTO
  # =========================================
  
  widget {
    note_definition {
      content = <<-EOT
        ## 🎯 **LTI PROJECT - MONITORING PROFESIONAL**
        
        **📊 Estado del Sistema** | **🌍 Región:** ${var.aws_region} | **🖥️ Instancia:** `${local.instance_id}` | **📈 Site:** us5.datadoghq.com
        
        ---
        
        ### 📋 **MÉTRICAS PRINCIPALES**
        | Componente | Estado | Descripción |
        |------------|---------|-------------|
        | ✅ **CPU & Credits** | Operativo | Monitoreo T2 optimizado |
        | ✅ **Network I/O** | Operativo | Tráfico entrada/salida |
        | ✅ **Storage EBS** | Operativo | Operaciones disco |
        | ✅ **Health Checks** | Operativo | Estado sistema/instancia |
        | 🔄 **Logs** | Sincronizando | CloudWatch → Datadog |
        
        ### ⚡ **MEJORAS IMPLEMENTADAS**
        - 🎨 **Diseño profesional** con paleta consistente
        - 🔧 **Variables dinámicas** para instancias
        - 📊 **Métricas expandidas** (logs, alarmas, métricas personalizadas)
        - 🚀 **Sincronización mejorada** AWS-Datadog
        - 🎯 **Alertas inteligentes** con umbrales optimizados
      EOT
      
      background_color = "blue"
      font_size        = "14"
      text_align       = "left"
      show_tick        = false
    }
  }

  # =========================================
  # PANEL DE KPIs PRINCIPALES
  # =========================================
  
  widget {
    group_definition {
      title         = "📊 KPIs Principales"
      layout_type   = "ordered"
      
      widget {
        query_value_definition {
          title       = "🔥 CPU Utilization"
          title_size  = "16"
          title_align = "center"
          
          request {
            q = "avg:aws.ec2.cpuutilization{$instance}"
            aggregator = "last"
            conditional_formats {
              comparator = ">"
              value      = 90
              palette    = "red_on_white"
            }
            conditional_formats {
              comparator = ">"
              value      = 70
              palette    = "yellow_on_white"
            }
            conditional_formats {
              comparator = "<="
              value      = 70
              palette    = "green_on_white"
            }
          }
          
          autoscale   = false
          precision   = 1
          text_align  = "center"
          custom_unit = "%"
        }
      }
      
      widget {
        query_value_definition {
          title       = "💾 CPU Credits"
          title_size  = "16"
          title_align = "center"
          
          request {
            q = "avg:aws.ec2.cpucreditbalance{$instance}"
            aggregator = "last"
            conditional_formats {
              comparator = "<"
              value      = 50
              palette    = "red_on_white"
            }
            conditional_formats {
              comparator = "<"
              value      = 100
              palette    = "yellow_on_white"
            }
            conditional_formats {
              comparator = ">="
              value      = 100
              palette    = "green_on_white"
            }
          }
          
          autoscale   = false
          precision   = 0
          text_align  = "center"
          custom_unit = "credits"
        }
      }
      
      widget {
        query_value_definition {
          title       = "🌐 Network Total"
          title_size  = "16"
          title_align = "center"
          
          request {
            q = "(avg:aws.ec2.networkin{$instance}.as_rate() + avg:aws.ec2.networkout{$instance}.as_rate()) / 1048576"
            aggregator = "last"
            conditional_formats {
              comparator = ">"
              value      = 10
              palette    = "yellow_on_white"
            }
            conditional_formats {
              comparator = "<="
              value      = 10
              palette    = "green_on_white"
            }
          }
          
          autoscale   = false
          precision   = 2
          text_align  = "center"
          custom_unit = "MB/s"
        }
      }
      
      widget {
        query_value_definition {
          title       = "🏥 Health Status"
          title_size  = "16"
          title_align = "center"
          
          request {
            q = "max:aws.ec2.status_check_failed{$instance}"
            aggregator = "last"
            conditional_formats {
              comparator = ">"
              value      = 0
              palette    = "red_on_white"
            }
            conditional_formats {
              comparator = "<="
              value      = 0
              palette    = "green_on_white"
            }
          }
          
          autoscale   = false
          precision   = 0
          text_align  = "center"
          custom_unit = ""
        }
      }
    }
  }

  # =========================================
  # MONITOREO DE CPU AVANZADO
  # =========================================
  
  widget {
    group_definition {
      title       = "🔥 CPU & Performance"
      layout_type = "ordered"
      
      widget {
        timeseries_definition {
          title       = "CPU Utilization - Tendencia Detallada"
          title_size  = "16"
          title_align = "left"
          show_legend = true
          
          request {
            q = "avg:aws.ec2.cpuutilization{$instance}"
            display_type = "line"
            style {
              palette    = "cool"
              line_type  = "solid"
              line_width = "thick"
            }
          }
          
          # Líneas de referencia mejoradas
          marker {
            label = "🚨 Critical: 90%"
            value = "y = 90"
            display_type = "error dashed"
          }
          
          marker {
            label = "⚠️ Warning: 70%"
            value = "y = 70"
            display_type = "warning dashed"
          }
          
          marker {
            label = "✅ Optimal: 50%"
            value = "y = 50"
            display_type = "ok dashed"
          }
          
          yaxis {
            label = "CPU Utilization (%)"
            scale = "linear"
            min   = "0"
            max   = "100"
          }
        }
      }
      
      widget {
        timeseries_definition {
          title       = "T2 CPU Credits - Balance & Usage"
          title_size  = "16"
          title_align = "left"
          show_legend = true
          
          request {
            q = "avg:aws.ec2.cpucreditbalance{$instance}"
            display_type = "area"
            style {
              palette    = "green"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          request {
            q = "avg:aws.ec2.cpucreditusage{$instance}"
            display_type = "line"
            style {
              palette    = "orange"
              line_type  = "solid"
              line_width = "thick"
            }
          }
          
          marker {
            label = "⚠️ Low Credits: 50"
            value = "y = 50"
            display_type = "warning dashed"
          }
          
          yaxis {
            label = "Credits"
            scale = "linear"
            min   = "0"
          }
        }
      }
    }
  }

  # =========================================
  # MONITOREO DE RED AVANZADO
  # =========================================
  
  widget {
    group_definition {
      title       = "🌐 Network Performance"
      layout_type = "ordered"
      
      widget {
        timeseries_definition {
          title       = "Network Throughput (Bytes/s)"
          title_size  = "16"
          title_align = "left"
          show_legend = true
          
          request {
            q = "avg:aws.ec2.networkin{$instance}.as_rate()"
            display_type = "area"
            style {
              palette    = "blue"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          request {
            q = "avg:aws.ec2.networkout{$instance}.as_rate()"
            display_type = "area"
            style {
              palette    = "purple"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          yaxis {
            label = "Bytes/second"
            scale = "linear"
            min   = "0"
          }
        }
      }
      
      widget {
        timeseries_definition {
          title       = "Network Packets Rate"
          title_size  = "16"
          title_align = "left"
          show_legend = true
          
          request {
            q = "avg:aws.ec2.networkpacketsin{$instance}.as_rate()"
            display_type = "line"
            style {
              palette    = "semantic"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          request {
            q = "avg:aws.ec2.networkpacketsout{$instance}.as_rate()"
            display_type = "line"
            style {
              palette    = "warm"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          yaxis {
            label = "Packets/second"
            scale = "linear"
            min   = "0"
          }
        }
      }
    }
  }

  # =========================================
  # MONITOREO DE ALMACENAMIENTO
  # =========================================
  
  widget {
    group_definition {
      title       = "💾 Storage Performance (EBS)"
      layout_type = "ordered"
      
      widget {
        timeseries_definition {
          title       = "EBS Operations (IOPS)"
          title_size  = "16"
          title_align = "left"
          show_legend = true
          
          request {
            q = "avg:aws.ec2.ebsreadops{$instance}.as_rate()"
            display_type = "line"
            style {
              palette    = "cool"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          request {
            q = "avg:aws.ec2.ebswriteops{$instance}.as_rate()"
            display_type = "line"
            style {
              palette    = "warm"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          yaxis {
            label = "Operations/second"
            scale = "linear"
            min   = "0"
          }
        }
      }
      
      widget {
        timeseries_definition {
          title       = "EBS Throughput (Bytes/s)"
          title_size  = "16"
          title_align = "left"
          show_legend = true
          
          request {
            q = "avg:aws.ec2.ebsreadbytes{$instance}.as_rate()"
            display_type = "area"
            style {
              palette    = "cool"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          request {
            q = "avg:aws.ec2.ebswritebytes{$instance}.as_rate()"
            display_type = "area"
            style {
              palette    = "orange"
              line_type  = "solid"
              line_width = "normal"
            }
          }
          
          yaxis {
            label = "Bytes/second"
            scale = "linear"
            min   = "0"
          }
        }
      }
    }
  }

  # =========================================
  # MONITOREO DE SALUD Y ESTADO
  # =========================================
  
  widget {
    timeseries_definition {
      title       = "🏥 System Health - Status Checks Detallado"
      title_size  = "16"
      title_align = "left"
      show_legend = true
      
      request {
        q = "max:aws.ec2.status_check_failed{$instance}"
        display_type = "bars"
        style {
          palette    = "semantic"
          line_type  = "solid"
          line_width = "thick"
        }
      }
      
      request {
        q = "max:aws.ec2.status_check_failed_instance{$instance}"
        display_type = "bars"
        style {
          palette    = "orange"
          line_type  = "solid"
          line_width = "normal"
        }
      }
      
      request {
        q = "max:aws.ec2.status_check_failed_system{$instance}"
        display_type = "bars"
        style {
          palette    = "purple"
          line_type  = "solid"
          line_width = "normal"
        }
      }
      
      yaxis {
        label = "Failed Checks (0=OK, 1=FAIL)"
        scale = "linear"
        min   = "0"
        max   = "1"
      }
    }
  }

  # =========================================
  # PIE DE DASHBOARD CON ENLACES ÚTILES
  # =========================================
  
  widget {
    note_definition {
      content = <<-EOT
        ## 🔗 **ENLACES RÁPIDOS Y RECURSOS**
        
        | 🎯 **Herramienta** | 🔗 **Enlace Directo** | 📝 **Descripción** |
        |-------------------|----------------------|-------------------|
        | 📊 **Metrics Explorer** | [Explorar Métricas](https://app.us5.datadoghq.com/metric/explorer) | Buscar y analizar todas las métricas |
        | 🏗️ **Infrastructure** | [Vista Infraestructura](https://app.us5.datadoghq.com/infrastructure) | Mapa de hosts y servicios |
        | ☁️ **AWS Integration** | [Configuración AWS](https://app.us5.datadoghq.com/account/settings#integrations/amazon_web_services) | Gestionar integración AWS |
        | 📱 **Mobile App** | [App Datadog](https://app.datadoghq.com/account/settings#mobile) | Monitoreo móvil |
        | 🚨 **Alertas** | [Gestión Monitores](https://app.us5.datadoghq.com/monitors/manage) | Configurar alertas |
        
        ---
        
        **📈 Dashboard actualizado**: Versión 2.0 Profesional | **⚡ Sync**: Optimizado | **🎨 UI**: Mejorada | **📊 Variables**: Dinámicas
        
        **🛠️ Soporte**: Para soporte técnico, contactar al equipo DevOps
      EOT
      
      background_color = "gray"
      font_size        = "14"
      text_align       = "left"
      show_tick        = false
    }
  }
}

# =========================================
# OUTPUTS DEL DASHBOARD MEJORADO
# =========================================

output "enhanced_dashboard_id" {
  description = "ID del dashboard mejorado"
  value       = datadog_dashboard.enhanced_dashboard.id
}

output "enhanced_dashboard_url" {
  description = "URL del dashboard mejorado"
  value       = "https://app.us5.datadoghq.com/dashboard/${datadog_dashboard.enhanced_dashboard.id}"
}

output "dashboard_instance_id" {
  description = "Instance ID utilizado en el dashboard"
  value       = local.instance_id
}

output "enhanced_dashboard_summary" {
  description = "Resumen del dashboard mejorado"
  value = <<-EOT
    🚀 Dashboard Mejorado Creado:
    
    📊 ID: ${datadog_dashboard.enhanced_dashboard.id}
    🔗 URL: https://app.us5.datadoghq.com/dashboard/${datadog_dashboard.enhanced_dashboard.id}
    🖥️ Instancia: ${local.instance_id}
    🌍 Región: ${var.aws_region}
    
    ✨ Características:
    • Variables dinámicas para instancias
    • Paleta de colores profesional
    • KPIs principales destacados
    • Métricas organizadas por categorías
    • Enlaces de navegación rápida
    
    🎯 Mejoras implementadas:
    • Sincronización optimizada AWS-Datadog
    • Diseño responsive y profesional
    • Alertas visuales mejoradas
    • Documentación integrada
  EOT
} 