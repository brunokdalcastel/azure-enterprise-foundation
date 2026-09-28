output "network_summary" {
  value = {
    vnet          = azurerm_virtual_network.foundation.name
    address_space = azurerm_virtual_network.foundation.address_space
    subnets       = { for name, subnet in azurerm_subnet.foundation : name => subnet.address_prefixes }
    admin_access  = var.admin_access_enabled
    tags_effect   = var.tags_policy_effect
  }
}
