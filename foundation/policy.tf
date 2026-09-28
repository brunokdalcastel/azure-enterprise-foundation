locals {
  policy_rules = {
    region = {
      if = { allOf = [
        { field = "location", notIn = [local.location, "global"] },
        { field = "type", notEquals = "Microsoft.Resources/subscriptions/resourceGroups" }
      ] }
      then = { effect = "Deny" }
    }
    tags = {
      if   = { anyOf = [for key, value in local.tags : { field = "tags['${key}']", notEquals = value }] }
      then = { effect = var.tags_policy_effect }
    }
    vm-sku = {
      if = { allOf = [
        { field = "type", equals = "Microsoft.Compute/virtualMachines" },
        { field = "Microsoft.Compute/virtualMachines/sku.name", notIn = [var.vm_size] }
      ] }
      then = { effect = "Deny" }
    }
  }
  policy_assignments = { for pair in setproduct(local.groups, toset(keys(local.policy_rules))) : "${pair[0]}-${pair[1]}" => { group = pair[0], policy = pair[1] } }
}

resource "azurerm_policy_definition" "foundation" {
  for_each     = local.policy_rules
  name         = "af-dev-${each.key}"
  display_name = "Azure Foundation Dev - ${each.key}"
  policy_type  = "Custom"
  mode         = "Indexed"
  metadata     = jsonencode({ category = "Azure Foundation Lab", version = "1.0.0" })
  policy_rule  = jsonencode(each.value)
}

resource "azurerm_resource_group_policy_assignment" "foundation" {
  for_each             = local.policy_assignments
  name                 = "af-${each.value.policy}"
  display_name         = "Foundation ${each.value.policy} - ${each.value.group}"
  resource_group_id    = azurerm_resource_group.foundation[each.value.group].id
  policy_definition_id = azurerm_policy_definition.foundation[each.value.policy].id
  enforce              = true
}
