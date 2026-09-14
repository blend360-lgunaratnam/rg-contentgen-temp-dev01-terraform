resource "azurerm_cognitive_account" "openai" {
  name                = "cog-contentgentemp-openai-dev01"
  resource_group_name = data.azurerm_resource_group.target.name
  location            = data.azurerm_resource_group.target.location
  kind                = "OpenAI"
  sku_name            = "S0"

  custom_subdomain_name         = "cog-contentgentemp-openai-dev01"
  public_network_access_enabled = true
}

resource "azurerm_cognitive_deployment" "text_embedding_3_small" {
  name                 = "loader-openai-textembedding3smalldev"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "text-embedding-3-small"
    version = "1"
  }

  scale {
    type     = "Standard"
    capacity = 1000
  }

  version_upgrade_option = "NoAutoUpgrade"
}

resource "azurerm_cognitive_deployment" "gpt_4o_mini" {
  name                 = "internal-openai-pmt-inj-det-gpt4o-mini-datazone-dev"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-4o-mini"
    version = "2024-07-18"
  }

  scale {
    type     = "GlobalStandard"
    capacity = 10000
  }

  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

resource "azurerm_cognitive_deployment" "gpt_5" {
  name                 = "gpt-5"
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = "gpt-5"
    version = "2025-08-07"
  }

  scale {
    type     = "GlobalStandard"
    capacity = 250
  }

  version_upgrade_option = "OnceNewDefaultVersionAvailable"
}

output "openai_endpoint" {
  description = "Endpoint URL for the Azure OpenAI resource."
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_primary_key" {
  description = "Primary API key for the Azure OpenAI resource."
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}
