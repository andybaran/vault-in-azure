

resource "azurerm_virtual_network" "vault-net" {
  name                = "${var.rg_name}-vault-net"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name
  address_space       = ["10.20.0.0/16"]
  tags = var.common-azure-tags
}
resource "azurerm_subnet" "vault-subnet" {
  name                 = "${var.rg_name}-vault-subnet"
  resource_group_name  = azurerm_resource_group.vault-rg.name
  virtual_network_name = azurerm_virtual_network.vault-net.name
  address_prefixes     = ["10.20.1.0/24"]
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Sql"]
}

resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.vault-rg.name
  virtual_network_name = azurerm_virtual_network.vault-net.name
  address_prefixes     = ["10.20.2.0/24"]
  service_endpoints    = ["Microsoft.KeyVault"]
}

resource "azurerm_network_interface" "vault-nic" {
  name                = "${var.rg_name}-vault-nic"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  ip_configuration {
    name                          = "${var.rg_name}-vault-nic-internal"
    subnet_id                     = azurerm_subnet.vault-subnet.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.1.100"
    primary                       = true
  }
  tags = var.common-azure-tags
}
resource "azurerm_network_interface" "postgres-nic" {
  name                = "${var.rg_name}-postgres-nic"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  ip_configuration {
    name                          = "${var.rg_name}-postgres-nic-internal"
    subnet_id                     = azurerm_subnet.vault-subnet.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.1.110"
    primary                       = true
  }
  tags = var.common-azure-tags
}

resource "azurerm_network_interface" "windows-nic" {
  name                = "${var.rg_name}-windows-nic"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  ip_configuration {
    name                          = "${var.rg_name}-windows-nic-internal"
    subnet_id                     = azurerm_subnet.vault-subnet.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.1.111"
    primary                       = true
  }
  tags = var.common-azure-tags
}

resource "azurerm_network_interface" "tfe-agent-nic" {
  name                = "${var.rg_name}-tfe-agent-nic"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  ip_configuration {
    name                          = "${var.rg_name}-tfe-agent-nic-internal"
    subnet_id                     = azurerm_subnet.vault-subnet.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.1.112"
    primary                       = true
  }
  tags = var.common-azure-tags
}
resource "azurerm_public_ip" "bastion-ip" {
  name                = "${var.rg_name}-bastion-ip"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = var.common-azure-tags
}

resource "azurerm_network_security_group" "vault-nsg" {
  name                = "${var.rg_name}-vault-nsg"
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Vault"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

    security_rule {
    name                       = "postgres"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = var.common-azure-tags
}

resource "azurerm_network_interface_security_group_association" "vault-nic-sg-association" {
  network_interface_id      = azurerm_network_interface.vault-nic.id
  network_security_group_id = azurerm_network_security_group.vault-nsg.id

}