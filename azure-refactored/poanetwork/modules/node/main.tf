# Create public IP
resource "azurerm_public_ip" "node" {
    name                         = "${var.prefix}${var.role}-ip"
    location                     = "${var.region}"
    resource_group_name          = "${var.resource_group_name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "${var.environment_name}"
    }
}

resource "azurerm_network_security_rule" "SSH" {
  count = "${contains(var.opened_ports, "ssh") ? 1 : 0}"
  name                       = "SSH"
  priority                   = 1001
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "HHTPS" {
  count = "${contains(var.opened_ports, "https") ? 1 : 0}"
  name                       = "HTTPS"
  priority                   = 1002
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "RPC" {
  count = "${contains(var.opened_ports, "rpc") ? 1 : 0}"
  name                       = "RPC"
  priority                   = 1003
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8545"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "P2P-TCP" {
  count = "${contains(var.opened_ports, "p2p/tcp") ? 1 : 0}"
  name                       = "P2P-TCP"
  priority                   = 1004
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "30303"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "P2P-UDP" {
  count = "${contains(var.opened_ports, "p2p/udp") ? 1 : 0}"
  name                       = "P2P-UDP"
  priority                   = 1005
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "udp"
  source_port_range          = "*"
  destination_port_range     = "30303"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "node" {
    name                = "${var.prefix}${var.role}-security-group"
    location            = "${var.region}"
    resource_group_name = "${var.resource_group_name}"

    tags {
        environment = "${var.environment_name}"
    }
}

# Create network interface
resource "azurerm_network_interface" "node" {
    name                      = "${var.prefix}${var.role}-network-card"
    location                  = "${var.region}"
    resource_group_name       = "${var.resource_group_name}"
    network_security_group_id = "${azurerm_network_security_group.node.id}"

    ip_configuration {
        name                          = "${var.prefix}${var.role}-ip"
        subnet_id                     = "${var.subnet_id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.node.id}"
    }

    tags {
        environment = "${var.environment_name}"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "node" {
    name                  = "${var.prefix}${var.role}-vm-${var.network_name}"
    location              = "${var.region}"
    resource_group_name   = "${var.resource_group_name}"
    network_interface_ids = ["${azurerm_network_interface.node.id}"]
    # 1 vCPU, 3.5 Gb of RAM
    vm_size               = "${var.machine_type}"

    storage_os_disk {
        name              = "${var.prefix}${var.role}-disk-os"
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
        computer_name  = "${var.role}"
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

resource "local_file" "group_vars" {
  content = "${join("\n", var.config)}"
  filename = "${var.ansible_path}/group_vars/${var.role}"
}

resource "local_file" "admins" {
  count = "${var.role == "bootnode" ? 1 : 0}"
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${var.ansible_path}/files/admins.pub"
}

resource "local_file" "node" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${var.ansible_path}/files/ssh_${var.role}.pub"
}

resource "null_resource" "inventory" {

  triggers {
    vm = "${azurerm_virtual_machine.node.id}"
    ip = "${azurerm_public_ip.node.ip_address}"
  }

  provisioner "local-exec" {
    command = "echo '[${var.role}]\n${azurerm_public_ip.node.ip_address}' >> ${var.ansible_path}/hosts"
  }
}
