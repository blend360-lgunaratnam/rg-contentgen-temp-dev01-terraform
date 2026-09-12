resource "azurerm_cognitive_account" "document_intelligence" {
  name                = "cog-contentgentemp-docintel-dev01"
  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
  kind                = "FormRecognizer"
  sku_name            = "S0"

  public_network_access_enabled = true
}

output "document_intelligence_endpoint" {
  description = "Endpoint URL for the Document Intelligence resource."
  value       = azurerm_cognitive_account.document_intelligence.endpoint
}

output "document_intelligence_primary_key" {
  description = "Primary API key for the Document Intelligence resource."
  value       = azurerm_cognitive_account.document_intelligence.primary_access_key
  sensitive   = true
}