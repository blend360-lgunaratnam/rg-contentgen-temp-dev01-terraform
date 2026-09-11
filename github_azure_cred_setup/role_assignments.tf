# Control plane: create and modify Azure resources in this RG.
resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_resource_group.target.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

# Data plane: read and write the state blob. Required because the backend uses
# use_azuread_auth; Contributor does NOT grant blob data access.
resource "azurerm_role_assignment" "state_blob" {
  scope                = data.azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "contributor_aidan_bowie" {
  scope                = data.azurerm_resource_group.target.id
  role_definition_name = "Contributor"
  principal_id         = data.azuread_user.aidan_bowie.object_id
  principal_type       = "User"
}
