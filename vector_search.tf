resource "databricks_vector_search_endpoint" "contentgentemp" {
  provider      = databricks.workspace
  name          = "vs-contentgentemp-dev01"
  endpoint_type = "STANDARD"
}

