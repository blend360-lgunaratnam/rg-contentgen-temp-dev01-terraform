output "client_id" {
  description = "Set as the AZURE_CLIENT_ID GitHub variable."
  value       = azurerm_user_assigned_identity.github.client_id

}

output "principal_id" {
  description = "Object ID of the identity; what role assignments target."
  value       = azurerm_user_assigned_identity.github.principal_id
}

output "tenant_id" {
  value = azurerm_user_assigned_identity.github.tenant_id
}