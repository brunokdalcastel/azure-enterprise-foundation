resource "azurerm_virtual_network" "foundation" {
  name                = "vnet-foundation-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["network"].name
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
  depends_on          = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_subnet" "foundation" {
  for_each                        = local.subnets
  name                            = "snet-${each.key}"
  resource_group_name             = azurerm_resource_group.foundation["network"].name
  virtual_network_name            = azurerm_virtual_network.foundation.name
  address_prefixes                = [each.value]
  default_outbound_access_enabled = false
  lifecycle {
    replace_triggered_by = [azurerm_virtual_network.foundation]
  }
}

resource "azurerm_network_security_group" "foundation" {
  for_each            = local.subnets
  name                = "nsg-${each.key}-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["network"].name
  tags                = local.tags
  depends_on          = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_subnet_network_security_group_association" "foundation" {
  for_each                  = local.subnets
  subnet_id                 = azurerm_subnet.foundation[each.key].id
  network_security_group_id = azurerm_network_security_group.foundation[each.key].id
  depends_on                = [azurerm_network_security_rule.foundation]
}

locals {
  # Defaults Azure de tráfego lateral/Internet são sobrepostos pelos denies.
  common_rules = {
    deny-lateral-in = { priority = 4000, direction = "Inbound", access = "Deny", protocol = "*", source = "VirtualNetwork", destination = "*", ports = ["*"] }
    dns-out         = { priority = 100, direction = "Outbound", access = "Allow", protocol = "*", source = "*", destination = "168.63.129.16", ports = ["53"] }
    web-out         = { priority = 110, direction = "Outbound", access = "Allow", protocol = "Tcp", source = "*", destination = "Internet", ports = ["80", "443"] }
    ntp-out         = { priority = 120, direction = "Outbound", access = "Allow", protocol = "Udp", source = "*", destination = "Internet", ports = ["123"] }
    deny-other-out  = { priority = 4096, direction = "Outbound", access = "Deny", protocol = "*", source = "*", destination = "*", ports = ["*"] }
  }
  rules = merge(
    merge([for subnet in keys(local.subnets) : {
      for name, rule in local.common_rules : "${subnet}-${name}" => merge(rule, { subnet = subnet, name = name })
    }]...),
    {
      application-http-in = { subnet = "application", name = "allow-test-http-in", priority = 110, direction = "Inbound", access = var.http_test_access_enabled ? "Allow" : "Deny", protocol = "Tcp", source = "10.10.40.10", destination = "10.10.20.10", ports = ["80"] }
      test-http-out       = { subnet = "test", name = "allow-test-http-out", priority = 130, direction = "Outbound", access = "Allow", protocol = "Tcp", source = "10.10.40.10", destination = "10.10.20.10", ports = ["80"] }
    }
  )
}

resource "azurerm_network_security_rule" "foundation" {
  for_each                    = local.rules
  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = "*"
  destination_port_range      = length(each.value.ports) == 1 ? each.value.ports[0] : null
  destination_port_ranges     = length(each.value.ports) > 1 ? each.value.ports : null
  source_address_prefix       = each.value.source
  destination_address_prefix  = each.value.destination
  resource_group_name         = azurerm_resource_group.foundation["network"].name
  network_security_group_name = azurerm_network_security_group.foundation[each.value.subnet].name
  lifecycle {
    replace_triggered_by = [azurerm_network_security_group.foundation]
  }
}

resource "azurerm_network_security_rule" "admin" {
  for_each                    = var.admin_access_enabled && var.workload_enabled ? { application = local.subnets.application } : {}
  name                        = "allow-admin-rdp-in"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3389"
  source_address_prefixes     = [for ip in values(var.admin_ipv4s) : "${ip}/32"]
  destination_address_prefix  = each.value
  resource_group_name         = azurerm_resource_group.foundation["network"].name
  network_security_group_name = azurerm_network_security_group.foundation[each.key].name
  lifecycle {
    replace_triggered_by = [azurerm_network_security_group.foundation[each.key]]
  }
}
