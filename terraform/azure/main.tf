# Configure the Azure Provider
provider "azurerm" { }

# Use predefined resource group
data "azurerm_resource_group" "test" {
  name = "test-terraform"
}

# Create virtual network
resource "azurerm_virtual_network" "default" {
    name                = "default"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.region}"
    resource_group_name = "${data.azurerm_resource_group.test.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "default" {
    name                 = "default"
    resource_group_name  = "${data.azurerm_resource_group.test.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IP
resource "azurerm_public_ip" "nodeIp" {
    name                         = "nodeIp"
    location                     = "${var.region}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "ssh" {
    name                = "ssh"
    location            = "${var.region}"
    resource_group_name = "${data.azurerm_resource_group.test.name}"

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

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "nodeNIC" {
    name                      = "nodeNIC"
    location                  = "${var.region}"
    resource_group_name       = "${data.azurerm_resource_group.test.name}"
    network_security_group_id = "${azurerm_network_security_group.ssh.id}"

    ip_configuration {
        name                          = "default"
        subnet_id                     = "${azurerm_subnet.default.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.nodeIp.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "node" {
    name                  = "full-node"
    location              = "${var.region}"
    resource_group_name   = "${data.azurerm_resource_group.test.name}"
    network_interface_ids = ["${azurerm_network_interface.nodeNIC.id}"]
    # 1 vCPU, 1 Gb of RAM
    vm_size               = "Standard_B1s"

    storage_os_disk {
        name              = "default"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
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
        computer_name  = "full"
        admin_username = "poa"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/poa/.ssh/authorized_keys"
            key_data = "${file(var.ssh_public_key)}"
        }
    }

    tags {
        environment = "Terraform Demo"
    }
}

output "full-node-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}
