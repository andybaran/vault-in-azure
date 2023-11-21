
locals {
  application_id = "08cbf481-a81f-4ced-91c8-a9172e6c4549"
  role_def_name  = join("-", ["hcp-hvn-peering-access", local.application_id])
  vnet_id        = "/subscriptions/a5dcde43-26f8-45d1-8b41-2fa43ec7795f/resourceGroups/akb-tfc/providers/Microsoft.Network/virtualNetworks/akb-tfc-vault-net"
}

resource "azuread_service_principal" "principal" {
  application_id = local.application_id
}

resource "azurerm_role_definition" "definition" {
  name  = local.role_def_name
  scope = local.vnet_id

  assignable_scopes = [
    local.vnet_id
  ]

  permissions {
    actions = [
      "Microsoft.Network/virtualNetworks/peer/action",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/write"
    ]
  }
}

resource "azurerm_role_assignment" "role_assignment" {
  principal_id       = azuread_service_principal.principal.id
  role_definition_id = azurerm_role_definition.definition.role_definition_resource_id
  scope              = local.vnet_id
}