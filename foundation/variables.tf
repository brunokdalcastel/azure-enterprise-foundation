variable "location" {
  description = "Região da foundation; mudar exige revisar substituições da rede e grupos. Backend permanece separado."
  type        = string
  default     = "northcentralus"
}

variable "subscription_id" {
  type      = string
  sensitive = true
}

variable "admin_ipv4s" {
  type        = map(string)
  sensitive   = true
  description = "IPv4s individuais por local: trabalho fixo e casa temporário. Remoção de casa é explícita, não automática."
  validation {
    condition = length(var.admin_ipv4s) > 0 && alltrue([
      for ip in values(var.admin_ipv4s) : can(cidrnetmask("${ip}/32")) && !strcontains(ip, "/")
    ])
    error_message = "Informe pelo menos um IPv4 individual, sem máscara, por local."
  }
}

variable "admin_access_enabled" {
  description = "Abrir RDP apenas durante sessão administrativa; false até haver VM."
  type        = bool
  default     = false
}

variable "tags_policy_effect" {
  type    = string
  default = "Deny"
  validation {
    condition     = contains(["Audit", "Deny"], var.tags_policy_effect)
    error_message = "Use Audit inicialmente ou Deny após os testes de governança."
  }
}

variable "vm_size" {
  description = "Candidato da oferta gratuita Windows x64; validar disponibilidade antes de habilitar workload."
  type        = string
  default     = "Standard_B2ats_v2"
  validation {
    condition     = contains(["Standard_B1s", "Standard_B2ats_v2"], var.vm_size)
    error_message = "Nesta etapa, use apenas os candidatos x64 da oferta gratuita."
  }
}

variable "workload_enabled" {
  description = "Criar/remover o conjunto de workload mantendo rede e governança."
  type        = bool
  default     = false
}

variable "part5_enabled" {
  description = "Laboratório temporário de segmentação e RBAC; requer workload habilitado."
  type        = bool
  default     = false
  validation {
    condition     = !var.part5_enabled || var.workload_enabled
    error_message = "Parte 5 requer workload_enabled=true."
  }
}

variable "windows_admin_password" {
  type      = string
  sensitive = true
  default   = null
  validation {
    condition     = var.windows_admin_password == null ? true : length(var.windows_admin_password) >= 20
    error_message = "Use senha de pelo menos 20 caracteres, fora do Git."
  }
}

variable "monitoring_enabled" {
  type    = bool
  default = false
  validation {
    condition     = !var.monitoring_enabled || var.workload_enabled
    error_message = "Monitoramento temporário requer workload_enabled=true."
  }
}

variable "http_test_access_enabled" {
  description = "Permissão HTTP privada; false somente durante incidente controlado da Parte6."
  type        = bool
  default     = true
}

variable "alert_email" {
  type      = string
  sensitive = true
  default   = null
  validation {
    condition     = var.alert_email == null ? true : can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alert_email))
    error_message = "Informe o e-mail autorizado para notificações, fora do Git."
  }
}

variable "cpu_alert_threshold" {
  description = "Padrão80%; reduzir temporariamente no ensaio e restaurar após evidências."
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_alert_threshold >= 0 && var.cpu_alert_threshold <= 100
    error_message = "Limiar de CPU deve estar entre0 e100."
  }
}
