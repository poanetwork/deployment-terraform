# Create public IP
resource "azurerm_public_ip" "validator" {
    name                         = "${var.prefix}validator-ip"
    location                     = "${var.region}"
    resource_group_name          = "${var.resource_group_name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "${var.environment_name}"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "validator" {
    name                = "${var.prefix}validator-security-group"
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
        name                       = "P2P-TCP"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "30303"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "P2P-UDP"
        priority                   = 1005
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "udp"
        source_port_range          = "*"
        destination_port_range     = "30303"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "${var.environment_name}"
    }
}

# Create network interface
resource "azurerm_network_interface" "validator" {
    name                      = "${var.prefix}validator-network-card"
    location                  = "${var.region}"
    resource_group_name       = "${var.resource_group_name}"
    network_security_group_id = "${azurerm_network_security_group.validator.id}"

    ip_configuration {
        name                          = "${var.prefix}validator-ip-private"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.validator.id}"
    }

    tags {
        environment = "${var.environment_name}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "validator" {
    name                  = "${var.prefix}validator-vm"
    location              = "${var.region}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.validator.id}"]
    # 1 vCPU, 3.5 Gb of RAM
    vm_size               = "${var.machine_type}"

    storage_os_disk {
        name              = "${var.prefix}validator-disk-os"
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
        computer_name  = "validator"
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
        environment = "${var.environment_name}"
    }
}
