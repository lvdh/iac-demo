# azurerm_virtual_network
variable "cidr_network" {
  type = "list"
}

resource "azurerm_virtual_network" "avn01" {
  name                = "avn01-${var.alias}-${var.environment}-${var.deploy_id}"
  address_space       = "${var.cidr_network}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.arg.name}"

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

# azurerm_subnet
variable "cidr_subnet" {}

resource "azurerm_subnet" "asn01" {
  name                 = "asn01-${var.alias}-${var.environment}-${var.deploy_id}"
  resource_group_name  = "${azurerm_resource_group.arg.name}"
  virtual_network_name = "${azurerm_virtual_network.avn01.name}"
  address_prefix       = "${var.cidr_subnet}"
}

# azurerm_public_ip (load balancer IP)
resource "azurerm_public_ip" "albip01" {
  name                         = "albip01-${var.alias}-${var.environment}-${var.deploy_id}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.arg.name}"
  public_ip_address_allocation = "static"

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

# azurerm_lb (load balancer)
resource "azurerm_lb" "alb01" {
  name                = "alb01-${var.alias}-${var.environment}-${var.deploy_id}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.arg.name}"

  frontend_ip_configuration {
    name                 = "afipc01-${var.alias}-${var.environment}-${var.deploy_id}"
    public_ip_address_id = "${azurerm_public_ip.albip01.id}"
  }
}

# azurerm_lb_probe (HTTP)
resource "azurerm_lb_probe" "albp-alb01-http" {
  resource_group_name = "${azurerm_resource_group.arg.name}"
  loadbalancer_id     = "${azurerm_lb.alb01.id}"
  name                = "http-probe"
  port                = 80
  protocol            = "Http"
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}

# azurerm_lb_rule (HTTP)
resource "azurerm_lb_rule" "albr-alb01-http" {
  resource_group_name            = "${azurerm_resource_group.arg.name}"
  loadbalancer_id                = "${azurerm_lb.alb01.id}"
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "afipc01-${var.alias}-${var.environment}-${var.deploy_id}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.albbap01.id}"
}

# azurerm_public_ip (VM IP)
resource "azurerm_public_ip" "avmip" {
  count                        = "${var.vm_quantity}"
  name                         = "avmip${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.arg.name}"
  public_ip_address_allocation = "static"

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

# azurerm_network_interface
resource "azurerm_network_interface" "avmni" {
  count               = "${var.vm_quantity}"
  name                = "avmni${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.arg.name}"

  ip_configuration {
    name                                    = "aip${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
    subnet_id                               = "${azurerm_subnet.asn01.id}"
    private_ip_address_allocation           = "dynamic"
    public_ip_address_id                    = "${element(azurerm_public_ip.avmip.*.id, count.index)}"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.albbap01.id}"]
  }

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

# azurerm_lb_backend_address_pool (VMs)
resource "azurerm_lb_backend_address_pool" "albbap01" {
  name                = "albbap01-${var.alias}-${var.environment}-${var.deploy_id}"
  resource_group_name = "${azurerm_resource_group.arg.name}"
  loadbalancer_id     = "${azurerm_lb.alb01.id}"
}

# outputs
output "load_balancer_pub_ip" {
  value = "${azurerm_public_ip.albip01.ip_address}"
}

output "vm_ips" {
  value = "${join(",",azurerm_public_ip.avmip.*.ip_address)}"
}
