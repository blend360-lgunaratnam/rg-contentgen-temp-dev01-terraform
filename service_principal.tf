# Databricks-managed service principal (no Azure AD app registration involved —
# created directly via the Databricks API, so it needs Databricks admin rights
# only, not Entra ID Application Administrator rights).
resource "databricks_service_principal" "contentgentemp_app" {
  provider     = databricks.workspace
  display_name = "sp-contentgentemp-vectorsearch-dev01"
  active       = true
}

# Not managed here: OAuth secrets appear to only be readable/manageable by
# whoever created them (not by any other identity, CI's included — CI's plan
# fails trying to refresh this resource with "User is not authorized to
# perform this operation" even though it can read everything else). Generate
# the secret manually per-user, via the workspace admin console (Settings >
# Identity and access > Service principals > this SP > Secrets).

# Nobody has explicit permissions on the endpoint by default; CAN_MANAGE is
# what lets this SP create/drop vector search indexes on it.
resource "databricks_permissions" "contentgentemp_vector_search_endpoint" {
  provider                  = databricks.workspace
  vector_search_endpoint_id = databricks_vector_search_endpoint.contentgentemp.endpoint_id

  access_control {
    service_principal_name = databricks_service_principal.contentgentemp_app.application_id
    permission_level       = "CAN_MANAGE"
  }

  access_control {
    user_name        = "logi.gunaratnam@blend360.com"
    permission_level = "CAN_MANAGE"
  }
}
