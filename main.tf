data "azurerm_resource_group" "target" {
  name = "rg-contentgen-temp-dev01"
}

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

# Grants upload/download access via Azure AD (az login), rather than making the
# container publicly readable. CI cannot create this itself (see
# manual_databricks_identity_changes.md) - apply it locally with:
#   terraform apply -target=azurerm_role_assignment.contentgen_landing_logi_gunaratnam
# principal_id is logi.gunaratnam@blend360.com's AAD object ID. Hardcoded rather than
# looked up via the azuread provider, because CI's identity also lacks Microsoft Graph
# permissions to read users - so a data source lookup fails in CI's plan too.
resource "azurerm_role_assignment" "contentgen_landing_logi_gunaratnam" {
  scope                = azurerm_storage_container.contentgen_landing.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "49ed08da-43e1-4cb6-85fa-50c8bb7fa7e3"
  principal_type       = "User"
}


resource "azurerm_role_assignment" "contentgen_landing_aidan_bowie" {
  scope                = azurerm_storage_container.contentgen_landing.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "3729640c-5305-45a1-8e84-4881f9592236"
  principal_type       = "User"
}
