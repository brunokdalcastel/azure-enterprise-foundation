data "azurerm_client_config" "current" {}

locals {
  tags = {
    Environment = "Lab"
    Owner       = "CloudTeam"
    Project     = "AzureFoundation"
    CostCenter  = "IT-Lab"
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "state" {
  name     = "rg-tfstate-lab-brs-01"
  location = "brazilsouth"
  tags     = local.tags
}

resource "azurerm_storage_account" "state" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.state.name
  location                        = azurerm_resource_group.state.location
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  access_tier                     = "Hot"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  public_network_access_enabled   = true
  tags                            = local.tags

  network_rules {
    default_action = "Deny"
    bypass         = ["None"]
    ip_rules       = values(var.admin_ipv4s)
  }

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }
}

# storage_account_id usa a API de gerenciamento para criar o container.
resource "azurerm_storage_container" "state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "state_writer" {
  scope                = azurerm_storage_container.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "User"
}
