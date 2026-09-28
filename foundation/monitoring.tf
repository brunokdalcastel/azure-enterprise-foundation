resource "azurerm_monitor_action_group" "lab" {
  count               = var.monitoring_enabled ? 1 : 0
  name                = "ag-lab-dev-ncu-01"
  resource_group_name = azurerm_resource_group.foundation["operations"].name
  short_name          = "lab-alerts"
  tags                = local.tags
  email_receiver {
    name                    = "lab-owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
  lifecycle {
    precondition {
      condition     = var.alert_email != null
      error_message = "Confirmar destinatário antes de habilitar notificações."
    }
  }
  depends_on = [azurerm_resource_group_policy_assignment.foundation]
}

resource "azurerm_monitor_metric_alert" "cpu" {
  count               = var.monitoring_enabled ? 1 : 0
  name                = "alert-cpu-web-dev-ncu-01"
  resource_group_name = azurerm_resource_group.foundation["operations"].name
  scopes              = [azurerm_windows_virtual_machine.web[0].id]
  description         = "CPU média acima do limiar; ensaio temporário com evidência e remoção."
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.tags
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_alert_threshold
  }
  action {
    action_group_id = azurerm_monitor_action_group.lab[0].id
  }
}

resource "azurerm_monitor_metric_alert" "availability" {
  count               = var.monitoring_enabled ? 1 : 0
  name                = "alert-availability-web-dev-ncu-01"
  resource_group_name = azurerm_resource_group.foundation["operations"].name
  scopes              = [azurerm_windows_virtual_machine.web[0].id]
  description         = "Disponibilidade da VM; não equivale à saúde do IIS."
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  auto_mitigate       = true
  tags                = local.tags
  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Minimum"
    operator         = "LessThan"
    threshold        = 1
  }
  action {
    action_group_id = azurerm_monitor_action_group.lab[0].id
  }
}
