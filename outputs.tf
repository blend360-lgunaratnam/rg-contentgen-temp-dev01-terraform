output "contentgentemp_sp_client_id" {
  value = databricks_service_principal.contentgentemp_app.application_id
}

output "contentgentemp_warehouse_id" {
  value = databricks_sql_endpoint.contentgentemp.id
}
