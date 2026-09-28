locals {
  personas = var.part5_enabled ? toset(["network", "analyst", "developer", "auditor"]) : toset([])
  persona_roles = var.part5_enabled ? {
    network            = { persona = "network", role = "Network Contributor", group = "network" }
    analyst_vm         = { persona = "analyst", role = "Virtual Machine Contributor", group = "workload" }
    analyst_read       = { persona = "analyst", role = "Reader", group = "network" }
    developer_read     = { persona = "developer", role = "Reader", group = "workload" }
    auditor_network    = { persona = "auditor", role = "Reader", group = "network" }
    auditor_workload   = { persona = "auditor", role = "Reader", group = "workload" }
    auditor_operations = { persona = "auditor", role = "Reader", group = "operations" }
  } : {}
}

resource "azurerm_user_assigned_identity" "persona" {
  for_each            = local.personas
  name                = "id-lab-${each.key}-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["operations"].name
  tags                = local.tags
  depends_on          = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_role_assignment" "persona" {
  for_each                         = local.persona_roles
  scope                            = azurerm_resource_group.foundation[each.value.group].id
  role_definition_name             = each.value.role
  principal_id                     = azurerm_user_assigned_identity.persona[each.value.persona].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_role_definition" "power" {
  count       = var.part5_enabled ? 1 : 0
  name        = "Lab VM Power Operator"
  scope       = azurerm_resource_group.foundation["workload"].id
  description = "Laboratório: ler, iniciar, reiniciar e desalocar VM; sem Run Command ou alterações de rede."
  permissions {
    actions = [
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action"
    ]
  }
  assignable_scopes = [azurerm_resource_group.foundation["workload"].id]
}

resource "azurerm_role_assignment" "power" {
  count                            = var.part5_enabled ? 1 : 0
  scope                            = azurerm_windows_virtual_machine.web[0].id
  role_definition_id               = azurerm_role_definition.power[0].role_definition_resource_id
  principal_id                     = azurerm_user_assigned_identity.persona["developer"].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true
}

resource "azurerm_public_ip" "test" {
  count               = var.part5_enabled ? 1 : 0
  name                = "pip-test-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["workload"].name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
  depends_on          = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_network_interface" "test" {
  count               = var.part5_enabled ? 1 : 0
  name                = "nic-test-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["workload"].name
  tags                = local.tags
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.foundation["test"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.40.10"
    public_ip_address_id          = azurerm_public_ip.test[0].id
  }
  depends_on = [azurerm_subnet_network_security_group_association.foundation]
}

resource "azurerm_windows_virtual_machine" "test" {
  count                 = var.part5_enabled ? 1 : 0
  name                  = "vm-test-dev-ncu-01"
  computer_name         = "wintest01"
  location              = local.location
  resource_group_name   = azurerm_resource_group.foundation["workload"].name
  size                  = var.vm_size
  admin_username        = "labadmin"
  admin_password        = var.windows_admin_password
  network_interface_ids = [azurerm_network_interface.test[0].id]
  secure_boot_enabled   = true
  vtpm_enabled          = true
  disk_controller_type  = "SCSI"
  provision_vm_agent    = true
  patch_mode            = "AutomaticByOS"
  tags                  = local.tags
  identity {
    type         = "UserAssigned"
    identity_ids = [for identity in azurerm_user_assigned_identity.persona : identity.id]
  }
  os_disk {
    name                 = "osdisk-test-dev-ncu-01"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
    disk_size_gb         = 32
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-datacenter-core-smalldisk-g2"
    version   = "17763.9245.260906"
  }
  boot_diagnostics {}
  depends_on = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "test" {
  count                 = var.part5_enabled ? 1 : 0
  virtual_machine_id    = azurerm_windows_virtual_machine.test[0].id
  location              = local.location
  enabled               = true
  daily_recurrence_time = "2200"
  timezone              = "E. South America Standard Time"
  tags                  = local.tags
  notification_settings {
    enabled = false
  }
}
