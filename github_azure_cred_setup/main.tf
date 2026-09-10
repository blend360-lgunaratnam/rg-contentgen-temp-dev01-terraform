locals {
  github_repo = "blend360-lgunaratnam/rg-contentgen-temp-dev01-terraform"
  # One federated credential per workflow context. The subject claim differs per trigger,
  # and a job declaring `environment:` uses the environment form even on main.
  federated_subjects = {
    pull-request   = "repo:${local.github_repo}:pull_request"
    main-branch    = "repo:${local.github_repo}:ref:refs/heads/main"
    env-production = "repo:${local.github_repo}:environment:production"
  }
}

data "azurerm_resource_group" "target" {
  name = "rg-contentgen-temp-dev01"
}

data "azurerm_storage_account" "tfstate" {
  name                = "statfstatecontentgentemp"
  resource_group_name = data.azurerm_resource_group.target.name
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "id-github-contentgen"
  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
}

resource "azurerm_federated_identity_credential" "github" {
  for_each = local.federated_subjects

  name                = each.key
  resource_group_name = data.azurerm_resource_group.target.name
  parent_id           = azurerm_user_assigned_identity.github.id
  issuer              = "https://token.actions.githubusercontent.com"
  audience            = ["api://AzureADTokenExchange"]
  subject             = each.value
}

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
