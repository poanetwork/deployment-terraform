# Create public IP
resource "azurerm_public_ip" "bootnode" {
    name                         = "${var.prefix}bootnode-ip"
    location                     = "${var.region}"
    resource_group_name          = "${var.resource_group_name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "${var.environment_name}"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "bootnode" {
    name                = "${var.prefix}bootnode-security-group"
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
resource "azurerm_network_interface" "bootnode" {
    name                      = "${var.prefix}bootnode-network-card"
    location                  = "${var.region}"
    resource_group_name       = "${var.resource_group_name}"
    network_security_group_id = "${azurerm_network_security_group.bootnode.id}"

    ip_configuration {
        name                          = "${var.prefix}bootnode-ip"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.bootnode.id}"
    }

    tags {
        environment = "${var.environment_name}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "bootnode" {
    name                  = "${var.prefix}bootnode-vm-${var.network_name}"
    location              = "${var.region}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.bootnode.id}"]
    # 1 vCPU, 3.5 Gb of RAM
    vm_size               = "${var.machine_type}"

    storage_os_disk {
        name              = "${var.prefix}bootnode-disk-os"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "${lookup(var.image_publisher, var.platform)}"
        offer     = "${lookup(var.image_offer, var.platform)}"
        sku       = "${lookup(var.image_version, var.platform)}"
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

    tags {
        environment = "${var.environment_name}"
    }
}

data "template_file" "group_vars" {
  template = "${file("${path.module}/templates/bootnode.yml.tpl")}"

  vars {
    node_fullname = "${var.node_name}"
    node_admin_email = "${var.node_admin_email}"
  }
}

resource "local_file" "group_vars" {
  content = "${data.template_file.group_vars.rendered}"
  filename = "${var.ansible_path}/group_vars/bootnode"
}

resource "local_file" "admins" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${var.ansible_path}/files/admins.pub"
}

resource "local_file" "bootnode" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${var.ansible_path}/files/ssh_bootnode.pub"
}
