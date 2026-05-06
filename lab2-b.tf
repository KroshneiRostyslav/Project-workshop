provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "az104-rg2"
  location = "Poland Central"

  tags = {
    "Cost Center" = "000"
  }
}

data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

resource "azurerm_policy_assignment" "inherit_tag" {
  name                 = "inherit-costcenter-tag"
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  scope                = azurerm_resource_group.rg.id

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = {
      value = "Cost Center"
    }
  })
}

resource "azurerm_role_assignment" "policy_role" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_policy_assignment.inherit_tag.identity[0].principal_id
}

resource "azurerm_storage_account" "example" {
  name                     = "workshopstorage"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [
    azurerm_policy_assignment.inherit_tag,
    azurerm_role_assignment.policy_role
  ]
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg.id
  lock_level = "CanNotDelete"
}