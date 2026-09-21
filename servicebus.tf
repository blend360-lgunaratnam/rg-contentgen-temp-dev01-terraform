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

# max_delivery_count is a retry limit, not a concurrency limit: it caps how many
# times a message may be attempted before dead-lettering, and does nothing to
# serialise delivery. At 1, a single expired lock or transient handler failure
# discarded the message permanently with no second attempt, which silently lost
# reference-load messages and hung content generation runs forever. Consumer-side
# concurrency is capped instead by maxConcurrentHandlers in
# ai_backend/dapr_components_contentgen/pubsub.yml.
#
# lock_duration defaults to PT1M, but one vdb_loader document takes 60-85s
# (Document Intelligence extraction + chunking + embedding). PT5M is the maximum
# Service Bus allows.

resource "azurerm_servicebus_subscription" "vdb_loader" {
  name               = "vdb-loader"
  topic_id           = azurerm_servicebus_topic.vdb_loader_events.id
  max_delivery_count = 10
  lock_duration      = "PT5M"
}

resource "azurerm_servicebus_subscription" "content_gen" {
  name               = "content-gen"
  topic_id           = azurerm_servicebus_topic.content_gen_main_events.id
  max_delivery_count = 10
  lock_duration      = "PT5M"
}

resource "azurerm_servicebus_subscription" "content_gen_ai" {
  name               = "content-gen-ai"
  topic_id           = azurerm_servicebus_topic.content_gen_ai_events.id
  max_delivery_count = 10
  lock_duration      = "PT5M"
}

resource "azurerm_servicebus_subscription" "content_gen_errors" {
  name               = "content-gen"
  topic_id           = azurerm_servicebus_topic.content_gen_error_events.id
  max_delivery_count = 10
  lock_duration      = "PT5M"
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

# Owner on the resource group is a control-plane role: it can create and delete
# topics, but grants no access to the MESSAGES inside them. Data operations -
# peeking a subscription, or receiving to drain a dead-letter queue - need a
# data-plane role, exactly like the Storage Blob Data Contributor grant in main.tf.
# Without this the portal's Service Bus Explorer refuses to purge a DLQ, which is
# needed whenever a poison message has to be cleared before re-running a flow.
#
# Same CI caveat as main.tf: principal_id is hardcoded rather than looked up via the
# azuread provider, because CI's identity lacks Microsoft Graph permission to read
# users, so a data source lookup fails in CI's plan. Apply locally with:
#   terraform apply -target=azurerm_role_assignment.servicebus_data_owner_logi_gunaratnam
resource "azurerm_role_assignment" "servicebus_data_owner_logi_gunaratnam" {
  scope                = azurerm_servicebus_namespace.contentgentemp.id
  role_definition_name = "Azure Service Bus Data Owner"
  principal_id         = "49ed08da-43e1-4cb6-85fa-50c8bb7fa7e3"
  principal_type       = "User"
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
