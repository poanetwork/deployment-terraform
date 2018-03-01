# Create public IP
resource "azurerm_public_ip" "netstat" {
    name                         = "${var.prefix}-netstat"
    location                     = "${var.region}"
    resource_group_name          = "${var.resource_group_name}"
    public_ip_address_allocation = "static"

    tags {
        env = "${var.env_tag}"
    }
}

# Create network interface
resource "azurerm_network_interface" "netstat" {
    name                      = "${var.prefix}-netstat"
    location                  = "${var.region}"
    resource_group_name       = "${var.resource_group_name}"
    network_security_group_id = "${azurerm_network_security_group.netstat.id}"

    ip_configuration {
        name                          = "${var.prefix}-netstat"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.netstat.id}"
    }

    tags {
        env = "${var.env_tag}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "netstat" {
    count = "${var.servers}"
    name                  = "${var.prefix}-netstat"
    location              = "${var.region}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.netstat.id}"]
    # 1 vCPU, 3.5 Gb of RAM
    vm_size               = "${var.machine_type}"

    storage_os_disk {
        name              = "${var.prefix}-netstat"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    # delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true

    os_profile {
        computer_name  = "netstat"
        admin_username = "poa"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys = [
          {
              path     = "/home/poa/.ssh/authorized_keys"
              key_data = "${file(var.ssh_public_key)}"
          },
          {
              path     = "/home/poa/.ssh/authorized_keys"
              key_data = "${file(var.ssh_public_key_ansible)}"
          }
        ]
    }

    tags {
        env = "${var.env_tag}"
    }
}

# Create Network Security Group and rule for netstat node
resource "azurerm_network_security_group" "netstat" {
    name                = "${var.prefix}-netstat"
    location            = "${var.region}"
    resource_group_name = "${var.resource_group_name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTPS"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP-3000"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        env = "${var.env_tag}"
    }

}
