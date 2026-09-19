data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "healthcare" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "healthcare" {
  name                = var.vnet_name
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
}

resource "azurerm_subnet" "web" {
  name                 = "snet-web"
  resource_group_name  = azurerm_resource_group.healthcare.name
  virtual_network_name = azurerm_virtual_network.healthcare.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "api" {
  name                 = "snet-api"
  resource_group_name  = azurerm_resource_group.healthcare.name
  virtual_network_name = azurerm_virtual_network.healthcare.name
  address_prefixes     = ["10.10.2.0/24"]

  service_endpoints = ["Microsoft.KeyVault"]
}

resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.healthcare.name
  virtual_network_name = azurerm_virtual_network.healthcare.name
  address_prefixes     = ["10.10.3.0/24"]
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-web"
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
}

resource "azurerm_network_security_group" "api" {
  name                = "nsg-api"
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
}

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data"
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "api" {
  subnet_id                 = azurerm_subnet.api.id
  network_security_group_id = azurerm_network_security_group.api.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

resource "azurerm_network_security_rule" "web_allow_https" {
  name                        = "Allow-Internet-To-Web-HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.healthcare.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "web_deny_vnet" {
  name                        = "Deny-Other-VNet-To-Web"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.10.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.healthcare.name
  network_security_group_name = azurerm_network_security_group.web.name
}

resource "azurerm_network_security_rule" "api_allow_web_https" {
  name                        = "Allow-Web-To-API-HTTPS"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.10.1.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.healthcare.name
  network_security_group_name = azurerm_network_security_group.api.name
}

resource "azurerm_network_security_rule" "api_deny_vnet" {
  name                        = "Deny-Other-VNet-To-API"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.10.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.healthcare.name
  network_security_group_name = azurerm_network_security_group.api.name
}

resource "azurerm_network_security_rule" "data_allow_api_sql" {
  name                        = "Allow-API-To-Data-SQL"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = "10.10.2.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.healthcare.name
  network_security_group_name = azurerm_network_security_group.data.name
}

resource "azurerm_network_security_rule" "data_deny_vnet" {
  name                        = "Deny-Other-VNet-To-Data"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.10.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.healthcare.name
  network_security_group_name = azurerm_network_security_group.data.name
}

resource "azurerm_user_assigned_identity" "api" {
  name                = "id-api-healthcare"
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
}

resource "azurerm_log_analytics_workspace" "healthcare" {
  name                = "law-healthcare-threatlab"
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_key_vault" "healthcare" {
  name                = "kv-hcthreat-bg"
  location            = azurerm_resource_group.healthcare.location
  resource_group_name = azurerm_resource_group.healthcare.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = "standard"

  rbac_authorization_enabled       = true
  public_network_access_enabled   = true
  soft_delete_retention_days      = 7
  purge_protection_enabled        = false

  network_acls {
    default_action = "Deny"
    bypass         = "None"

    virtual_network_subnet_ids = [
      azurerm_subnet.api.id
    ]
  }
}

resource "azurerm_role_assignment" "api_key_vault_secrets_user" {
  scope                = azurerm_key_vault.healthcare.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-keyvault-to-law"
  target_resource_id         = azurerm_key_vault.healthcare.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.healthcare.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
