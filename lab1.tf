provider "azuread" {}

variable "domain_name" {
    description = "Azure AD domain"
    type = string
    default = "rostuslav056gmail.onmicrosoft.com"
}

resource "azuread_user" "user1" {
    user_principal_name = "az104-user1@${var.domain_name}"
    display_name = "az104-user1"

    password = "StrongPassw0rd123!"
    force_password_change = true

    account_enabled = true

    job_title = "IT Lab Administrator"
    department = "IT"

    usage_location = "US"
}

resource "azuread_invitation" "guest" {
    user_email_address = "rostyslav.kroshnei.23@pnu.edu.ua"
    redirect_url = "https://portal.azure.com"

    display_name = "Rostyslav"

    message {
        body = "Administrators that manage the IT lab"
    }
}

resource "azuread_group" "administrators" {
    display_name = "IT Lab Administrators"
    description = "Administrators that manage the IT lab"

    security_enabled = true
}

resource "azuread_group_member" "membership" {
    group_object_id = azuread_group.administrators.id
    member_object_id = azuread_user.user1.id
}

resource "azuread_group_member" "guest_membership" {
    group_object_id = azuread_group.administrators.id
    member_object_id = azuread_invitation.guest.user_id
}