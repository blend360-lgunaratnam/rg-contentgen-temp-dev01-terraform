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

variable "create_new_metastore" {
  description = "TODO(confirm-metastore): resolve via `az databricks account metastore list` (needs account-admin auth) once network access is restored. false = assign to an existing metastore (assumed default — metastores are typically one-per-region-per-account). true = create a new one."
  type    = bool
  default = false
}

data "databricks_metastore" "existing" {
  count    = var.create_new_metastore ? 0 : 1
  provider = databricks.account
  name     = "" # TODO: fill in once confirmed (or use `id = var.existing_metastore_id`)
}

resource "databricks_metastore" "new" {
  count         = var.create_new_metastore ? 1 : 0
  provider      = databricks.account
  name          = "metastore-contentgentemp-dev01"
  storage_root  = "abfss://${azurerm_storage_container.unity_catalog_root.name}@${azurerm_storage_account.unity_catalog.name}.dfs.core.windows.net/"
  region        = data.azurerm_resource_group.target.location
  force_destroy = true # dev/temp env — allow clean teardown
}

locals {
  metastore_id = var.create_new_metastore ? databricks_metastore.new[0].id : data.databricks_metastore.existing[0].id
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.account
  workspace_id = azurerm_databricks_workspace.this.workspace_id
  metastore_id = local.metastore_id
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
  metastore_id = local.metastore_id
  name         = "contentgentemp_cat_dev"
  comment      = "Catalog for contentgen-temp-dev01 vector search indexes and related UC-managed data."

  depends_on = [databricks_metastore_assignment.this]
}

resource "databricks_schema" "contentgentemp" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.contentgentemp.name
  name         = "contentgentemp_schema_dev"
  comment      = "Schema holding vector search index source/delta tables for contentgen-temp-dev01."
}
