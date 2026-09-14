# Databricks-managed service principal (no Azure AD app registration involved
# — created directly via the Databricks API, so it needs Databricks admin
# rights only, not Entra ID Application Administrator rights).
resource "databricks_service_principal" "contentgentemp_app" {
  provider     = databricks.workspace
  display_name = "sp-contentgentemp-vectorsearch-dev01"
  active       = true
}

# OAuth secret creation for this SP fails via Terraform every time (both
# workspace- and account-scoped providers), always "User is not authorized to
# perform this operation" — this isn't a scope issue (confirmed by testing
# the account-level provider separately), just something Terraform's ambient
# auth can't do here. Generate the secret manually via the workspace admin
# console instead (Settings > Identity and access > Service principals >
# sp-contentgentemp-vectorsearch-dev01 > Secrets).

# Nobody has explicit permissions on the endpoint by default; CAN_MANAGE is
# what lets this SP create/drop vector search indexes on it.
resource "databricks_permissions" "contentgentemp_vector_search_endpoint" {
  provider                  = databricks.workspace
  vector_search_endpoint_id = databricks_vector_search_endpoint.contentgentemp.endpoint_id

  access_control {
    service_principal_name = databricks_service_principal.contentgentemp_app.application_id
    permission_level       = "CAN_MANAGE"
  }
}
