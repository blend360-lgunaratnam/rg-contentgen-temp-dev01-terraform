provider "databricks" {
  alias                        = "workspace"
  host                         = azurerm_databricks_workspace.this.workspace_url
  azure_workspace_resource_id  = azurerm_databricks_workspace.this.id
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.azuredatabricks.net"
  account_id = "f7de7d65-0ddb-44d7-a053-66e2138695ac"
}

resource "azurerm_databricks_workspace" "this" {
  name                         = "dbw-contentgentemp-dev01"
  resource_group_name          = data.azurerm_resource_group.target.name
  location                     = data.azurerm_resource_group.target.location
  sku                          = "premium"
  managed_resource_group_name  = "rg-dbw-contentgentemp-dev01-managed"
}

resource "azurerm_storage_account" "unity_catalog" {
  name                     = "stacontentgentucdev01"
  resource_group_name      = data.azurerm_resource_group.target.name
  location                 = data.azurerm_resource_group.target.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "unity_catalog_root" {
  name                  = "unity-catalog-root"
  storage_account_name  = azurerm_storage_account.unity_catalog.name
  container_access_type = "private"
}

resource "azurerm_databricks_access_connector" "unity_catalog" {
  name                = "dbac-contentgentemp-uc-dev01"
  resource_group_name = data.azurerm_resource_group.target.name
  location             = data.azurerm_resource_group.target.location
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "unity_catalog_storage" {
  scope                = azurerm_storage_account.unity_catalog.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.unity_catalog.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}