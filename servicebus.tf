resource "azurerm_servicebus_namespace" "contentgentemp" {
  name                = "sb-contentgentemp-dev01"
  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
  sku                 = "Standard"
}

resource "azurerm_servicebus_topic" "vdb_loader_events" {
  name         = "vdb_loader_events"
  namespace_id = azurerm_servicebus_namespace.contentgentemp.id
}

resource "azurerm_servicebus_topic" "content_gen_main_events" {
  name         = "content_gen_main_events"
  namespace_id = azurerm_servicebus_namespace.contentgentemp.id
}

resource "azurerm_servicebus_topic" "content_gen_ai_events" {
  name         = "content_gen_ai_events"
  namespace_id = azurerm_servicebus_namespace.contentgentemp.id
}

resource "azurerm_servicebus_topic" "content_gen_error_events" {
  name         = "content_gen_error_events"
  namespace_id = azurerm_servicebus_namespace.contentgentemp.id
}

resource "azurerm_servicebus_subscription" "vdb_loader" {
  name               = "vdb-loader"
  topic_id           = azurerm_servicebus_topic.vdb_loader_events.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_subscription" "content_gen" {
  name               = "content-gen"
  topic_id           = azurerm_servicebus_topic.content_gen_main_events.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_subscription" "content_gen_ai" {
  name               = "content-gen-ai"
  topic_id           = azurerm_servicebus_topic.content_gen_ai_events.id
  max_delivery_count = 1
}

resource "azurerm_servicebus_subscription" "content_gen_errors" {
  name               = "content-gen"
  topic_id           = azurerm_servicebus_topic.content_gen_error_events.id
  max_delivery_count = 1
}

# Shared connection string for local Dapr sidecars (dropped into each app's secrets.json).
# Not scoped to an individual identity, so it works the same for any teammate who has it.
resource "azurerm_servicebus_namespace_authorization_rule" "dapr_local_dev" {
  name         = "dapr-local-dev"
  namespace_id = azurerm_servicebus_namespace.contentgentemp.id
  listen       = true
  send         = true
  manage       = false
}

output "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace used for Dapr pub/sub."
  value       = azurerm_servicebus_namespace.contentgentemp.name
}

output "servicebus_dapr_connection_string" {
  description = "Connection string for local Dapr sidecars to send/listen on the contentgen pub/sub topics."
  value       = azurerm_servicebus_namespace_authorization_rule.dapr_local_dev.primary_connection_string
  sensitive   = true
}
