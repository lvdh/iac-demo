# azurerm_virtual_machine
variable "vm_quantity" {
  default = 1
}
variable "vm_size" {
  default = "Standard_D1_v2"
}
variable "vm_admin_username" {
  default = "ubuntu"
}
variable "vm_admin_password" {
  default = "viua0JtQARSzr07yY7J0vM8TOeSZyH7btGzhrd848ieO3Tt8R159Hr7UiyEno0x"
}
variable "vm_admin_ssh_pubkey" {}
variable "vm_disable_ssh_pw_auth" {
  default = true
}
variable "vm_os_publisher" {
  default = "Canonical"
}
variable "vm_os_offer" {
  default = "UbuntuServer"
}
variable "vm_os_sku" {
  default = "16.04.0-LTS"
}
variable "vm_os_version" {
  default = "16.04.201611150"
}
variable "vm_os_disk_caching" {
  default = "ReadWrite"
}
variable "vm_os_disk_create_option" {
  default = "FromImage"
}
variable "vm_data_disk_size" {
  default = 20
}
variable "vm_data_disk_delete_on_termination" {
  default = false
}
variable "vm_data_disk_create_option" {
  default = "Empty"
}

resource "azurerm_availability_set" "aas01" {
  name                = "aas01-${var.alias}-${var.environment}-${var.deploy_id}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.arg.name}"

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

resource "azurerm_virtual_machine" "avm" {
  count                            = "${var.vm_quantity}"
  name                             = "avm${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
  location                         = "${var.location}"
  resource_group_name              = "${azurerm_resource_group.arg.name}"
  network_interface_ids            = ["${ element(azurerm_network_interface.avmni.*.id, count.index) }"]
  vm_size                          = "${var.vm_size}"
  delete_data_disks_on_termination = "${var.vm_data_disk_delete_on_termination}"
  availability_set_id              = "${azurerm_availability_set.aas01.id}"

  storage_image_reference {
    publisher = "${var.vm_os_publisher}"
    offer     = "${var.vm_os_offer}"
    sku       = "${var.vm_os_sku}"
    version   = "${var.vm_os_version}"
  }

  storage_os_disk {
    name          = "asod${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
    vhd_uri       = "${azurerm_storage_account.asa01.primary_blob_endpoint}${azurerm_storage_container.asc01.name}/asod${count.index}-${var.alias}-${var.environment}-${var.deploy_id}.vhd"
    caching       = "${var.vm_os_disk_caching}"
    create_option = "${var.vm_os_disk_create_option}"
  }

  storage_data_disk {
    name          = "asdd${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
    vhd_uri       = "${azurerm_storage_account.asa01.primary_blob_endpoint}${azurerm_storage_container.asc01.name}/asdd${count.index}-${var.alias}-${var.environment}-${var.deploy_id}.vhd"
    create_option = "${var.vm_data_disk_create_option}"
    disk_size_gb  = "${var.vm_data_disk_size}"
    lun           = 0 # Specifies the logical unit number of the data disk
  }

  os_profile {
    computer_name  = "avm${count.index}-${var.alias}-${var.environment}-${var.deploy_id}"
    admin_username = "${var.vm_admin_username}"
    admin_password = "${var.vm_admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = "${var.vm_disable_ssh_pw_auth}"

    ssh_keys {
      path     = "/home/${var.vm_admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.vm_admin_ssh_pubkey}")}"
    }
  }

  tags {
    terraform   = "true"
    alias       = "${var.alias}"
    environment = "${var.environment}"
    deploy_id   = "${var.deploy_id}"
  }
}

output "vm_names" {
  value = "${join(",",azurerm_virtual_machine.avm.*.name)}"
}
