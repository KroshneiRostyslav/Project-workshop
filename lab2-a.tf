provider "azurerm"{
    features {

    }
}

provider "azuread" {

}

resource "azurerm_management_group" mg {
    name = "az104-mg1"
    display_name = "az104-mg1"
}

resource "azuread_group" "helpdesk" {
    display_name = "helpdesk"
    security_enabled = true
}

data "azurerm_role_definition" "vm_contributor" {
    name = "Virtual Machine Contributor"
    scope = azurerm_management_group.mg.id
}

resource "azurerm_role_assignment" "vm_contributor_assignment" {
    scope = azurerm_management_group.mg.id
    role_definition_id = data.azurerm_role_definition.vm_contributor.id
    principal_id = azuread_group.helpdesk.object_id
}

resource "azurerm_role_definition" "custom_support" {
    name = "Custom Support Request"
    scope = azurerm_management_group.mg.id
    description = "A custom contributor role for support requests."

    permissions {
        actions = [
            "Microsoft.Support/*"
        ]

        not_actions = [
            "Microsoft.Support/register/action"
        ]

    }

    assignable_scopes = [
        azurerm_management_group.mg.id
    ]
}

resource "azurerm_role_assignment" "custom_support_assignment" {
    scope = azurerm_management_group.mg.id
    role_definition_id = azurerm_role_definition.custom_support.role_definition_resource_id
    principal_id = azuread_group.helpdesk.object_id
}