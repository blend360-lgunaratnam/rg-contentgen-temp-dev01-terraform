resource "databricks_sql_endpoint" "contentgentemp" {
  provider                  = databricks.workspace
  name                      = "sql-contentgentemp-dev01"
  cluster_size              = "2X-Small"
  warehouse_type            = "PRO"
  enable_serverless_compute = true
  auto_stop_mins            = 10
  max_num_clusters          = 1
}

# No default permissions on a new warehouse; grant explicit access, matching
# the vector search endpoint pattern in service_principal.tf.
resource "databricks_permissions" "contentgentemp_sql_warehouse" {
  provider        = databricks.workspace
  sql_endpoint_id = databricks_sql_endpoint.contentgentemp.id

  access_control {
    service_principal_name = databricks_service_principal.contentgentemp_app.application_id
    permission_level       = "CAN_USE"
  }

  access_control {
    user_name        = "logi.gunaratnam@blend360.com"
    permission_level = "CAN_MANAGE"
  }
}
