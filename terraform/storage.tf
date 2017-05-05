# azurerm_storage_account
variable "account_type" {
  default = "Standard_LRS"
}

resource "azurerm_storage_account" "asa01" {
  name                = "asa01${var.deploy_id}${var.environment}" # No dashes/underscores
  resource_group_name = "${azurerm_resource_group.arg.name}"
  location            = "${var.location}"
  account_type        = "${var.account_type}"

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

# azurerm_storage_container
variable "container_access_type" {
  default = "private"
}

resource "azurerm_storage_container" "asc01" {
  name                  = "asc01-${var.alias}-${var.environment}-${var.deploy_id}"
  resource_group_name   = "${azurerm_resource_group.arg.name}"
  storage_account_name  = "${azurerm_storage_account.asa01.name}"
  container_access_type = "${var.container_access_type}"
}
