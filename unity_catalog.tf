resource "databricks_storage_credential" "unity_catalog" {
  provider = databricks.workspace
  name     = "cred-contentgentemp-uc-dev01"

  azure_managed_identity {
    access_connector_id = azurerm_databricks_access_connector.unity_catalog.id
  }
}

resource "databricks_external_location" "unity_catalog_root" {
  provider        = databricks.workspace
  name            = "ext-loc-contentgentemp-uc-dev01"
  url             = "abfss://${azurerm_storage_container.unity_catalog_root.name}@${azurerm_storage_account.unity_catalog.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.unity_catalog.id
}

data "databricks_metastore" "existing" {
  provider     = databricks.account
  metastore_id = "8f82548c-bb16-48e4-83e2-3e61ae1a4c20" # metastore_azure_uksouth
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.account
  workspace_id = azurerm_databricks_workspace.this.workspace_id
  metastore_id = data.databricks_metastore.existing.metastore_id
}

# `default_catalog_name` on databricks_metastore_assignment is deprecated —
# set the workspace default catalog via databricks_default_namespace_setting
# instead (workspace-scoped, so uses the databricks.workspace provider).
resource "databricks_default_namespace_setting" "this" {
  provider = databricks.workspace
  namespace {
    value = databricks_catalog.contentgentemp.name
  }
  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_catalog" "contentgentemp" {
  provider     = databricks.workspace
  metastore_id = data.databricks_metastore.existing.metastore_id
  name         = "contentgentemp_cat_dev"
  comment      = "Catalog for contentgen-temp-dev01 vector search indexes and related UC-managed data."
  storage_root = databricks_external_location.unity_catalog_root.url

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_schema" "contentgentemp" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.contentgentemp.name
  name         = "contentgentemp_schema_dev"
  comment      = "Schema holding vector search index source/delta tables for contentgen-temp-dev01."
}
