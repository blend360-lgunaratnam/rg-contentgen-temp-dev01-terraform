output "contentgentemp_sp_client_id" {
  value = databricks_service_principal.contentgentemp_app.application_id
}

output "contentgentemp_sp_client_secret" {
  value     = databricks_service_principal_secret.contentgentemp_app.secret
  sensitive = true
}
