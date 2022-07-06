resource "azurerm_bastion_host" "gatekeeper" {
  name                = var.azure_bastion_host_name
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  ip_configuration {
    name                 = "${var.azure_bastion_host_name}-bastion-pub-ip"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastion-ip.id
  }
  tags = var.common-azure-tags
}

resource "azurerm_key_vault" "vault-vault" {
  name                        = var.azure_keyvault_name
  location                    = azurerm_resource_group.vault-rg.location
  resource_group_name         = azurerm_resource_group.vault-rg.name
  enabled_for_deployment      = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  tags = var.common-azure-tags

   # access policy for the hashicorp vault service principal.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "get",
      "WrapKey",
      "UnwrapKey",
    ]

  }

    # access policy for the user that is currently running terraform.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
        "Backup", 
        "Create", 
        "Decrypt", 
        "Delete", 
        "Encrypt", 
        "get", 
        "import", 
        "list", 
        "purge", 
        "recover", 
        "restore", 
        "sign", 
        "UnwrapKey", 
        "Update", 
        "verify", 
        "WrapKey",
    ]

    certificate_permissions = [
        "Backup",
        "Create",
        "Delete",
        "deleteIssuers",
        "get",
        "getIssuers",
        "import",
        "list",
        "listIssuers",
        "manageContacts",
        "manageIssuers",
        "purge",
        "recover",
        "restore",
        "setIssuers",
        "Update",
    ]

    secret_permissions = [
        "Backup",
        "Delete",
        "get",
        "list",
        "purge",
        "recover",
        "restore",
        "Set",
    ]

    storage_permissions = [
        "Backup",
        "Delete",
        "deletesas",
        "get",
        "getsas",
        "list",
        "listsas",
        "purge",
        "recover",
        "regeneratekey",
        "restore",
        "Set",
        "setsas",
        "Update",
    ]


  }

  network_acls {
    default_action = "Allow"
    bypass = "AzureServices" 
    ip_rules = [ "75.2.98.97/32",
                                  "99.83.150.238/32",
                                  "52.86.200.106/32","52.86.201.227/32",
                                  "52.70.186.109/32","44.236.246.186/32",
                                  "54.185.161.84/32","44.238.78.236/32",
                                ]
    virtual_network_subnet_ids = [ azurerm_subnet.vault-subnet.id,
                                  azurerm_subnet.AzureBastionSubnet.id,
                                  ]
  }
}

resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits = "2048"

}

resource "azurerm_key_vault_key" "unsealer" {
    depends_on = [
      azurerm_key_vault.vault-vault
    ]
  name         = "Vault-key"
  key_vault_id = azurerm_key_vault.vault-vault.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "WrapKey",
    "UnwrapKey",
  ]
  tags = var.common-azure-tags
}