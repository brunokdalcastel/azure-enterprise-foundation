resource "azurerm_public_ip" "web" {
  count               = var.workload_enabled ? 1 : 0
  name                = "pip-web-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["workload"].name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
  depends_on          = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_network_interface" "web" {
  count               = var.workload_enabled ? 1 : 0
  name                = "nic-web-dev-ncu-01"
  location            = local.location
  resource_group_name = azurerm_resource_group.foundation["workload"].name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.foundation["application"].id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.20.10"
    public_ip_address_id          = azurerm_public_ip.web[0].id
  }
  depends_on = [azurerm_subnet_network_security_group_association.foundation]
}

resource "azurerm_windows_virtual_machine" "web" {
  count                 = var.workload_enabled ? 1 : 0
  name                  = "vm-web-dev-ncu-01"
  computer_name         = "winweb01"
  location              = local.location
  resource_group_name   = azurerm_resource_group.foundation["workload"].name
  size                  = var.vm_size
  admin_username        = "labadmin"
  admin_password        = var.windows_admin_password
  network_interface_ids = [azurerm_network_interface.web[0].id]
  secure_boot_enabled   = true
  vtpm_enabled          = true
  disk_controller_type  = "SCSI"
  provision_vm_agent    = true
  patch_mode            = "AutomaticByOS"
  tags                  = local.tags

  os_disk {
    name                 = "osdisk-web-dev-ncu-01"
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
  lifecycle {
    precondition {
      condition     = var.windows_admin_password != null
      error_message = "Forneça senha local protegida antes de habilitar workload."
    }
  }
  depends_on = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_virtual_machine_extension" "iis" {
  count                      = var.workload_enabled ? 1 : 0
  name                       = "configure-iis"
  virtual_machine_id         = azurerm_windows_virtual_machine.web[0].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = local.tags
  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(templatefile("${path.module}/scripts/Configure-IIS.ps1.tftpl", { admin_ips = join(",", values(var.admin_ipv4s)) }), "UTF-16LE")}"
  })
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "web" {
  count                 = var.workload_enabled ? 1 : 0
  virtual_machine_id    = azurerm_windows_virtual_machine.web[0].id
  location              = local.location
  enabled               = true
  daily_recurrence_time = "2200"
  timezone              = "E. South America Standard Time"
  tags                  = local.tags
  notification_settings {
    enabled = false
  }
}
