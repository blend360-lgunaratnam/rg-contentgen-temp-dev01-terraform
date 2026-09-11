locals {
  # This repo issues immutable-ID subject claims: GitHub embeds the numeric owner ID and
  # repo ID in the token's `sub`, as "OWNER@OWNER_ID/REPO@REPO_ID". The plain name form
  # does NOT match and fails with AADSTS700213. The IDs are stable across renames, which
  # is the point of the format. Read the exact value from a failed run's error message.
  github_repo = "blend360-lgunaratnam@138681317/rg-contentgen-temp-dev01-terraform@1362803273"

  # One federated credential per workflow context. The subject claim differs per trigger,
  # and a job declaring `environment:` uses the environment form even on main.
  federated_subjects = {
    pull-request    = "repo:${local.github_repo}:pull_request"
    main-branch     = "repo:${local.github_repo}:ref:refs/heads/main"
    env-development = "repo:${local.github_repo}:environment:development"
  }
}

data "azurerm_resource_group" "target" {
  name = "rg-contentgen-temp-dev01"
}

data "azuread_user" "aidan_bowie" {
  user_principal_name = "aidan.bowie@blend360.com"
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
