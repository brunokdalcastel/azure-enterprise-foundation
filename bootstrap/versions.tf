terraform {
  required_version = ">= 1.14.3, < 2.0.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.74.0"
    }
  }
  # O bootstrap não deve depender do backend que ele próprio cria/remove.
  backend "local" {}
}

provider "azurerm" {
  features {}
  subscription_id                 = var.subscription_id
  storage_use_azuread             = true
  resource_provider_registrations = "none"
}
