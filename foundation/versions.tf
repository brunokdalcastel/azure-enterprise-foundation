terraform {
  required_version = ">= 1.14.3, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.74.0"
    }
  }
  # Configuração real gerada a partir do bootstrap, fora do Git.
  backend "azurerm" {}
}

# Marcador preservado do teste de backend da Parte 2.
resource "terraform_data" "backend_validation" {
  input = "foundation-dev-backend-ready"
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  storage_use_azuread             = true
  resource_provider_registrations = "none"
}
