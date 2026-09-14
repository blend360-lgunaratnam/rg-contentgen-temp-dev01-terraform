resource "databricks_storage_credential" "unity_catalog" {
  provider = databricks.workspace
  name     = "cred-contentgentemp-uc-dev01"
  # Unity Catalog ownership is separate from Azure RBAC/Databricks account-admin.
  # This must be the GitHub CI identity (not whoever applies this resource),
  # otherwise CI's own `terraform plan` can't even read the object back.
  # id-github-contentgen's client ID, from the github_azure_cred_setup state
  # (a separate state — not referenceable directly from here).
  owner = data.azurerm_user_assigned_identity.github.client_id

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

locals {
  # metastore_azure_uksouth — the account's existing shared metastore for this
  # region. New premium workspaces in a region that already has a metastore
  # get auto-assigned to it at creation time (account-level "automatic Unity
  # Catalog enablement"), so no `databricks_metastore_assignment` resource is
  # needed here — that API call requires Databricks account-admin status,
  # which this identity doesn't have, and would just be redoing what the
  # platform already does on workspace creation.
  metastore_id = "8f82548c-bb16-48e4-83e2-3e61ae1a4c20"
}

# `default_catalog_name` on databricks_metastore_assignment is deprecated —
# set the workspace default catalog via databricks_default_namespace_setting
# instead (workspace-scoped, so uses the databricks.workspace provider).
resource "databricks_default_namespace_setting" "this" {
  provider = databricks.workspace
  namespace {
    value = databricks_catalog.contentgentemp.name
  }
}

resource "databricks_catalog" "contentgentemp" {
  provider     = databricks.workspace
  metastore_id = local.metastore_id
  name         = "contentgentemp_cat_dev"
  comment      = "Catalog for contentgen-temp-dev01 vector search indexes and related UC-managed data."
  storage_root = databricks_external_location.unity_catalog_root.url
}

resource "databricks_schema" "contentgentemp" {
  provider     = databricks.workspace
  catalog_name = databricks_catalog.contentgentemp.name
  name         = "contentgentemp_schema_dev"
  comment      = "Schema holding vector search index source/delta tables for contentgen-temp-dev01."
}

# The catalog/schema are owned by the GitHub CI identity (see the storage
# credential above for why). Without explicit grants, nobody else has any
# Unity Catalog privileges on them — they'd exist but be invisible to
# everyone else in Catalog Explorer. Granted to "account users" (dev/temp
# environment, simplest option, no per-person management).
resource "databricks_grants" "contentgentemp_catalog" {
  provider = databricks.workspace
  catalog  = databricks_catalog.contentgentemp.name

  grant {
    principal  = "account users"
    privileges = ["USE_CATALOG", "USE_SCHEMA"]
  }
}

resource "databricks_grants" "contentgentemp_schema" {
  provider = databricks.workspace
  schema   = "${databricks_catalog.contentgentemp.name}.${databricks_schema.contentgentemp.name}"

  grant {
    principal  = "account users"
    privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  }
}
