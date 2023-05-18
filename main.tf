terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
     # version = "3.00.0"
    }
    hcp = {
     source = "hashicorp/hcp"
    }
  }
}

# Configure the HCP Provider
provider "hcp" {
  
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
resource "azurerm_resource_group" "vault-rg" {
  name     = var.rg_name 
  location = "East US"   # https://azure.microsoft.com/en-us/global-infrastructure/geographies/#geographies
  tags = var.common-azure-tags
}


#Azure Log Analytics/Sentinel

resource "azurerm_log_analytics_workspace" "log-analytics-workspace" {
  name                = "linux-vault-workspace "
  location            = azurerm_resource_group.vault-rg.location
  resource_group_name = azurerm_resource_group.vault-rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

resource "azurerm_log_analytics_solution" "la-opf-solution-sentinel" {
  solution_name         = "SecurityInsights"
  location              = azurerm_resource_group.vault-rg.location
  resource_group_name   = azurerm_resource_group.vault-rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.log-analytics-workspace.id
  workspace_name        = azurerm_log_analytics_workspace.log-analytics-workspace.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

#data "azurerm_client_config" "current" {}

#  Virtual Machines
/* data "template_file" "vault-setup" {
  template = file("${path.module}/vault-setup.tpl")

  vars = {
    resource_group_name = var.rg_name
    vm_name             = var.vault_vm_name
    vault_license       = var.vault_license
    vault_version       = var.vault_version
  }
} */

/* data "template_file" "postgres-setup" {
  template = file("${path.module}/postgres-setup.tpl")
} */

data "template_file" "tfe-agent-setup" {
  template = file("${path.module}/tfe-agent-setup.tpl")

  vars = {
    tfc_agent_token = var.tfc_agent_token
    tfc_agent_name = var.tfc_agent_name
  }
}

/* resource "azurerm_linux_virtual_machine" "vault-vm" {
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

} */

/* resource "azurerm_linux_virtual_machine" "postgres_vm" {
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

} */

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

/* locals {
  virtual_machine_name = "${var.windows_vm_name}-dc"
  virtual_machine_fqdn = "${local.virtual_machine_name}.${var.active_directory_domain}"
  custom_data_params   = "Param($RemoteHostName = \"${local.virtual_machine_fqdn}\", $ComputerName = \"${local.virtual_machine_name}\")"
  custom_data_content  = "${local.custom_data_params} ${file("${path.module}/files/winrm.ps1")}"
} */

/* resource "azurerm_windows_virtual_machine" "windows-vm" {
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

    #patch_mode = "Manual"

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

} */

# Log Analytics
# https://learn.microsoft.com/en-us/azure/azure-monitor/agents/data-sources-syslog
# https://learn.microsoft.com/en-us/azure/azure-monitor/vm/monitor-virtual-machine

resource "azurerm_monitor_data_collection_rule" "vault-dcr" {
  name                = "linux-syslog"
  resource_group_name = azurerm_resource_group.vault-rg.name
  location            = azurerm_resource_group.vault-rg.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.log-analytics-workspace.id
      name                  = "vault-destination-log"
    }

    azure_monitor_metrics {
      name = "vault-destination-metrics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["vault-destination-log"]
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      name           = "vault-datasource-syslog"
      streams = ["Microsoft-Syslog"]
    }
  }
  description = "syslog data collection rule"
  tags = var.common-azure-tags
  depends_on = [
    azurerm_log_analytics_solution.la-opf-solution-sentinel
  ]
}


