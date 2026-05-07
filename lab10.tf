terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg1" {
  name     = "az104-rg-region1"
  location = "East US"
}

resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg-region2"
  location = "West US"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-vnet"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "vm-nic"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "vm" {
  name                = "az104-10-vm0"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  size                = "Standard_D2s_v3"
  admin_username      = "localadmin"
  admin_password      = "AzurePass123!"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-g2"
    version   = "latest"
  }
}

resource "azurerm_recovery_services_vault" "rsv1" {
  name                = "az104-rsv-region1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  sku                 = "Standard"
  soft_delete_enabled = true
}

resource "azurerm_backup_policy_vm" "backup_policy" {
  name                = "az104-backup"
  resource_group_name = azurerm_resource_group.rg1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv1.name

  backup {
    frequency = "Daily"
    time      = "00:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "vm_backup" {
  resource_group_name = azurerm_resource_group.rg1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv1.name
  source_vm_id        = azurerm_windows_virtual_machine.vm.id
  backup_policy_id    = azurerm_backup_policy_vm.backup_policy.id
}

resource "azurerm_storage_account" "logs" {
  name                     = "logsa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_recovery_services_vault" "rsv2" {
  name                = "az104-rsv-region2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  sku                 = "Standard"
  soft_delete_enabled = true
}

resource "azurerm_site_recovery_replication_policy" "rep_policy" {
  name                                                 = "default-rep-policy"
  recovery_vault_name                                  = azurerm_recovery_services_vault.rsv2.name
  resource_group_name                                  = azurerm_resource_group.rg2.name
  recovery_point_retention_in_minutes                  = 1440
  application_consistent_snapshot_frequency_in_minutes = 240
}

output "vm_id" {
  value = azurerm_windows_virtual_machine.vm.id
}

output "vault_region1" {
  value = azurerm_recovery_services_vault.rsv1.name
}

output "vault_region2" {
  value = azurerm_recovery_services_vault.rsv2.name
}