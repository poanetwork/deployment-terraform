# Configure the Azure Provider
provider "azurerm" { }

# Use predefined resource group
data "azurerm_resource_group" "test" {
  name = "test-terraform"
}

# Create virtual network
resource "azurerm_virtual_network" "default" {
    name                = "${var.prefix}-default"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.region}"
    resource_group_name = "${data.azurerm_resource_group.test.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "default" {
    name                 = "${var.prefix}-default"
    resource_group_name  = "${data.azurerm_resource_group.test.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IP
resource "azurerm_public_ip" "nodeIp" {
    name                         = "${var.prefix}-nodeIp"
    location                     = "${var.region}"
    resource_group_name          = "${data.azurerm_resource_group.test.name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "bootnode" {
    name                = "${var.prefix}-bootnode"
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
        name                       = "RPC"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8545"
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

    tags {
        environment = "Terraform Demo"
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
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "nodeNIC" {
    name                      = "${var.prefix}-nodeNIC"
    location                  = "${var.region}"
    resource_group_name       = "${data.azurerm_resource_group.test.name}"
    network_security_group_id = "${azurerm_network_security_group.bootnode.id}"

    ip_configuration {
        name                          = "${var.prefix}-default"
        subnet_id                     = "${azurerm_subnet.default.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.nodeIp.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Template for initial configuration bash script
data "template_file" "hosts" {
  template = "${file("${path.module}/hosts.tpl")}"

  vars {
    node_address = "${azurerm_public_ip.nodeIp.ip_address}"
  }
}

resource "local_file" "inventory" {
  depends_on = ["azurerm_public_ip.nodeIp"]
  content = "${data.template_file.hosts.rendered}"
  filename = "${path.module}/../../hosts"
}

# Create virtual machine
resource "azurerm_virtual_machine" "bootnode" {
    count = 0
    name                  = "${var.prefix}-bootnode"
    location              = "${var.region}"
    resource_group_name   = "${data.azurerm_resource_group.test.name}"
    network_interface_ids = ["${azurerm_network_interface.nodeNIC.id}"]
    # 1 vCPU, 1 Gb of RAM
    vm_size               = "Standard_B1s"
    depends_on = ["local_file.inventory"]

    storage_os_disk {
        name              = "${var.prefix}-default"
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
        computer_name  = "bootnode"
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

    provisioner "local-exec" {
        command = "cd ../.. && ansible-playbook playbooks/web.yaml"
    }

    tags {
        environment = "Terraform Demo"
    }
}

output "bootnode-ip" {
  value = "${azurerm_public_ip.nodeIp.ip_address}"
}
