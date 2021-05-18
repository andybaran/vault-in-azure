terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.46.0"

    }
  }
}

/*
# Random provider to guarantee some uniqueness
provider "random" {}

resource "random_string" "random-string" {
  length = 3
  special = false
}
*/

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
resource "azurerm_resource_group" "vault-rg" {
  name     = var.rg_name 
  location = "East US"   # https://azure.microsoft.com/en-us/global-infrastructure/geographies/#geographies
}

data "azurerm_client_config" "current" {}

#  Virtual Machines
data "template_file" "vault-setup" {
  template = file("${path.module}/vaultsetup.tpl")

  vars = {
    resource_group_name = var.rg_name
    vm_name             = var.vault_vm_name
    vault_version       = var.vault_version
    tenant_id           = var.ARM_TENANT_ID
    subscription_id     = var.ARM_SUBSCRIPTION_ID
    client_id           = var.ARM_CLIENT_ID
    client_secret       = var.ARM_CLIENT_SECRET
    vault_name          = azurerm_key_vault.vault-vault.name
    key_name            = azurerm_key_vault_key.unsealer.name
  }
}

data "template_file" "postgres-setup" {
  template = file("${path.module}/postgressetup.tpl")
}

resource "azurerm_linux_virtual_machine" "vault-vm" {
  name                = var.vault_vm_name
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location
  size                = "Standard_D4a_v4" #https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  custom_data         = base64encode(data.template_file.vault-setup.rendered)
  disable_password_authentication = false
  admin_username      = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.vault-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "postgres_vm" {
  name                = var.postgres_vm_name
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location
  size                = "Standard_D4a_v4" #https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  custom_data         = base64encode(data.template_file.postgres-setup.rendered)
  disable_password_authentication = false
  admin_username      = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.postgres-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_windows_virtual_machine" "windows-vm" {
  name = var.windows_vm_name
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location
  size                = "Standard_D4a_v4" #https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  admin_username = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [ azurerm_network_interface.windows-nic.id ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}