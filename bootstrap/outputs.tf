output "backend_config" {
  description = "Configuração não secreta; salvar em foundation/backend.local.hcl, fora do Git."
  value = {
    storage_account_name = azurerm_storage_account.state.name
    container_name       = azurerm_storage_container.state.name
    key                  = "foundation-dev.tfstate"
    use_azuread_auth     = true
    use_cli              = true
  }
}
