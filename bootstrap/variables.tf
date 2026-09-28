variable "subscription_id" {
  type        = string
  description = "Assinatura Free Trial validada no preflight."
  sensitive   = true
}

variable "storage_account_name" {
  type        = string
  description = "Nome globalmente único do backend."
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Use de 3 a 24 caracteres alfanuméricos minúsculos."
  }
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
