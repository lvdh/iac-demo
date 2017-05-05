# azurerm
variable "tenant_id" {}
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}

provider "azurerm" {
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
}

# azurerm_resource_group
resource "azurerm_resource_group" "arg" {
  name     = "arg-${var.alias}-${var.environment}-${var.deploy_id}"
  location = "${var.location}"

  tags {
    terraform   = "true"
    environment = "${var.environment}"
    alias       = "${var.alias}"
    deploy_id   = "${var.deploy_id}"
  }
}
