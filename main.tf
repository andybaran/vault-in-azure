terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.46.0"

    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}
resource "azurerm_resource_group" "vault-rg" {
  name     = var.rg_name 
  location = "East US"   # https://azure.microsoft.com/en-us/global-infrastructure/geographies/#geographies
  tags = var.common-azure-tags
}

data "azurerm_client_config" "current" {}

#  Virtual Machines
data "template_file" "vault-setup" {
  template = file("${path.module}/vault-setup.tpl")

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
  template = file("${path.module}/postgres-setup.tpl")
}

data "template_file" "tfe-agent-setup" {
  template = file("${path.module}/tfe-agent-setup.tpl")

  vars = {
    tfc_agent_token = var.tfc_agent_token
    tfc_agent_name = var.tfc_agent_name
  }
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

  tags = var.common-azure-tags

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

  tags = var.common-azure-tags

}

resource "azurerm_linux_virtual_machine" "tfe_agent_vm" {
  name                = var.tfc_agent_name
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location
  size                = "Standard_D4a_v4" #https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  custom_data         = base64encode(data.template_file.tfe-agent-setup.rendered)
  disable_password_authentication = false
  admin_username      = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [
    azurerm_network_interface.tfe-agent-nic.id,
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

  tags = var.common-azure-tags

}

locals {
  virtual_machine_name = "${var.windows_vm_name}-dc"
  virtual_machine_fqdn = "${local.virtual_machine_name}.${var.active_directory_domain}"
  custom_data_params   = "Param($RemoteHostName = \"${local.virtual_machine_fqdn}\", $ComputerName = \"${local.virtual_machine_name}\")"
  custom_data_content  = "${local.custom_data_params} ${file("${path.module}/files/winrm.ps1")}"
}

resource "azurerm_windows_virtual_machine" "windows-vm" {
  name = var.windows_vm_name
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location
  size                = "Standard_D4a_v4" #https://docs.microsoft.com/en-us/azure/virtual-machines/sizes
  admin_username = var.admin_username
  admin_password = var.admin_password
  network_interface_ids = [ azurerm_network_interface.windows-nic.id ]
  custom_data    = base64encode(local.custom_data_content)
  

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

    patch_mode = "Manual"

    additional_unattend_content {
      #pass         = "oobeSystem"
      #component    = "Microsoft-Windows-Shell-Setup"
      setting = "AutoLogon"
      content      = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled>true</Enabled><LogonCount>1</LogonCount><Username>${var.admin_username}</Username></AutoLogon>"
    }

    # Unattend config is to enable basic auth in WinRM, required for the provisioner stage.
    additional_unattend_content {
      #pass         = "oobeSystem"
      #component    = "Microsoft-Windows-Shell-Setup"
      setting = "FirstLogonCommands"
      content      = "${file("${path.module}/files/FirstLogonCommands.xml")}"
    }

  tags = var.common-azure-tags

}