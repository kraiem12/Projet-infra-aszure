resource "azurerm_resource_group" "G1" {
  name     = "GROUPE1"
  location = "France Central"
}

resource "azurerm_virtual_network" "vn" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.G1.location}"
  resource_group_name = "${azurerm_resource_group.G1.name}"
}

resource "azurerm_subnet" "sub1" {
  name                 = "SUBNET1"
  resource_group_name  = "${azurerm_resource_group.G1.name}"
  virtual_network_name = "${azurerm_virtual_network.vn.name}"
  address_prefix       = "10.0.2.0/24"
}
resource "azurerm_subnet" "sub2" {
  name                 = "SUBNET2"
  resource_group_name  = "${azurerm_resource_group.G1.name}"
  virtual_network_name = "${azurerm_virtual_network.vn.name}"
  address_prefix       = "10.0.3.0/24"
}
resource "azurerm_public_ip" "ipp" {
  name                         = "publicIPForLB1"
  location                     = "${azurerm_resource_group.G1.location}"
  resource_group_name          = "${azurerm_resource_group.G1.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_network_security_group" "lesports" {
  name                = "port"
  location            = "${azurerm_resource_group.G1.location}"
  resource_group_name = "${azurerm_resource_group.G1.name}"

  security_rule {
    name                       = "OK-HTTP-entrant1"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "OK-HTTP-entrant2"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}
resource "azurerm_network_interface" "interface1" {
  count               = 3
  name                = "acctni${count.index}"
  location            = "${azurerm_resource_group.G1.location}"
  resource_group_name = "${azurerm_resource_group.G1.name}"

  ip_configuration {
    name                          = "G1Configuration"
    subnet_id                     = "${azurerm_subnet.sub1.id}"
    private_ip_address_allocation = "dynamic"
  }
}
resource "azurerm_network_interface" "interface2" {
  count               = 1
  name                = "interface22${count.index}"
  location            = "${azurerm_resource_group.G1.location}"
  resource_group_name = "${azurerm_resource_group.G1.name}"

  ip_configuration {
    name                          = "G1Configuration"
    subnet_id                     = "${azurerm_subnet.sub2.id}"
    private_ip_address_allocation = "dynamic"

  }
}


resource "azurerm_virtual_machine" "slave" {
  count    = 3
  name     = "slave${count.index}"
  location = "${azurerm_resource_group.G1.location}"

  #availability_set_id   = "${azurerm_availability_set.avset.id}"
  resource_group_name   = "${azurerm_resource_group.G1.name}"
  network_interface_ids = ["${element(azurerm_network_interface.interface1.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"
    version = "latest"
}

  storage_os_disk {
    name              = "diskslave${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
     }

  os_profile {
    computer_name  = "hostname"
    admin_username = "G1admin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/G1admin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNLV5EjrbI5noWsox1RZ7xEroLKsXJJYKt7SyVGIjWVCIYKjUmwwm6xbAWckh94n/wB9vg7X8h0iSaa0pompFg/IOX5ulNAmk2vrMy4fTYxZ04wZ4BldXVtOKpQg1mgWuvOR5+kFX6avGFqp8WCQ3QlvBpu96xlBJQYype+6f/H1YrwA8T5x5vo10WraT8C5GdH5LeXI5JrpFAoV8b4SmebD3Wy8Fn1yjt1CrN4IJKEGBaab5+FTKf8L/Hpk+uHBJqVMnS/OQWW51Y2savEJBtARcR12SBN1J/TzuTdpirnEvsrrXDIDPMraPC2k1Vi6wswEBzvQISQmvaCitcVelJ user01@linux-8.home"

  }

}
}
resource "azurerm_virtual_machine" "ngnix" {
  count    = 1
  name     = "ngnix${count.index}"
  location = "${azurerm_resource_group.G1.location}"

  #availability_set_id   = "${azurerm_availability_set.avset.id}"
  resource_group_name   = "${azurerm_resource_group.G1.name}"
  network_interface_ids = ["${element(azurerm_network_interface.interface2.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7.5"

    version = "latest"
}

  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
   }

  os_profile {
    computer_name  = "hostname"
    admin_username = "G1admin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/G1admin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNLV5EjrbI5noWsox1RZ7xEroLKsXJJYKt7SyVGIjWVCIYKjUmwwm6xbAWckh94n/wB9vg7X8h0iSaa0pompFg/IOX5ulNAmk2vrMy4fTYxZ04wZ4BldXVtOKpQg1mgWuvOR5+kFX6avGFqp8WCQ3QlvBpu96xlBJQYype+6f/H1YrwA8T5x5vo10WraT8C5GdH5LeXI5JrpFAoV8b4SmebD3Wy8Fn1yjt1CrN4IJKEGBaab5+FTKf8L/Hpk+uHBJqVMnS/OQWW51Y2savEJBtARcR12SBN1J/TzuTdpirnEvsrrXDIDPMraPC2k1Vi6wswEBzvQISQmvaCitcVelJ user01@linux-8.home"

  }

  }
}

