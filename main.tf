data "azurerm_resource_group" "target" {
  name = "rg-contentgen-temp-dev01"
}

data "azurerm_client_config" "current" {}

data "azurerm_user_assigned_identity" "github" {
  name                = "id-github-contentgen"
  resource_group_name = data.azurerm_resource_group.target.name
}

resource "azurerm_storage_account" "contentgen_documents" {
  name                     = "stacontentgentempdev01"
  resource_group_name      = data.azurerm_resource_group.target.name
  location                 = data.azurerm_resource_group.target.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "contentgen_landing" {
  name                  = "contentgen-landing-dev"
  storage_account_name  = azurerm_storage_account.contentgen_documents.name
  container_access_type = "private"
}

# Grants the currently authenticated (az login) user upload/download access via Azure AD,
# rather than making the container publicly readable.
resource "azurerm_role_assignment" "contentgen_landing_current_user" {
  scope                = azurerm_storage_container.contentgen_landing.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}