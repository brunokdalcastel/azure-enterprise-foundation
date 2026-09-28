locals {
  location = var.location
  tags = {
    Environment = "Dev"
    Owner       = "CloudTeam"
    Project     = "AzureFoundation"
    CostCenter  = "IT-Lab"
    ManagedBy   = "Terraform"
  }
  groups = toset(["network", "workload", "operations"])
  subnets = {
    application = "10.10.20.0/24"
    test        = "10.10.40.0/24"
  }
}

resource "azurerm_resource_group" "foundation" {
  for_each = local.groups
  name     = "rg-${each.key}-dev-ncu-01"
  location = local.location
  tags     = local.tags
}
