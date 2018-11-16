# Create public IP
resource "azurerm_public_ip" "node" {
  count                        = "${var.lb_node_count + var.node_count}"
  name                         = "${var.prefix}${var.role}${count.index >= var.node_count ? "-lb" : ""}-ip-${count.index >= var.node_count ? count.index - var.node_count : count.index}"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "${var.environment_name}"
  }
}

resource "azurerm_availability_set" "node" {
  name                = "${var.prefix}${var.role}-lb-AvailabilitySet"
  count               = "${var.lb_node_count > 0 ? 1 : 0}"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"
  managed             = "true"

  tags {
    environment = "${var.environment_name}"
  }
}

locals {
  opened_ports = "${var.opened_ports_by_role[var.role]}"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "node" {
  count               = "${var.lb_node_count > 0 ? (var.node_count > 0 ? 2 : 1 ) : (var.node_count > 0 ? 1 : 0 )}"
  name                = "${var.prefix}${var.role}${count.index > 0 ? "-lb" : ""}-security-group"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    environment = "${var.environment_name}"
  }
}

resource "azurerm_network_security_rule" "node" {
  count                       = "${length(local.opened_ports) * (var.lb_node_count > 0 ? (var.node_count > 0 ? 2 : 1 ) : (var.node_count > 0 ? 1 : 0 ))}"
  name                        = "${var.prefix}${var.role}${count.index >= length(local.opened_ports) ? "-lb" : ""}-security-group-${element(local.opened_ports, (count.index >= length(local.opened_ports) ? count.index - length(local.opened_ports) : count.index))}"
  priority                    = "100${count.index >= length(local.opened_ports) ? count.index - length(local.opened_ports) : count.index}"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "${element(var.ports[element(local.opened_ports, (count.index >= length(local.opened_ports) ? count.index - length(local.opened_ports) : count.index))], 1)}"
  source_port_range           = "*"
  destination_port_range      = "${element(var.ports[element(local.opened_ports, (count.index >= length(local.opened_ports) ? count.index - length(local.opened_ports) : count.index))], 2)}"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${count.index >= length(local.opened_ports) ? element(azurerm_network_security_group.node.*.name, 1) : element(azurerm_network_security_group.node.*.name, 0)}"
}

# Create network interface
resource "azurerm_network_interface" "node" {
  count                     = "${var.lb_node_count + var.node_count}"
  name                      = "${var.prefix}${var.role}${count.index >= var.node_count ? "-lb" : ""}-network-card-count-${count.index >= var.node_count ? count.index - var.node_count : count.index}"
  location                  = "${var.region}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${count.index >= var.node_count ? element(azurerm_network_security_group.node.*.id, 1) : element(azurerm_network_security_group.node.*.id, 0)}"

  ip_configuration {
    name                          = "${var.prefix}${var.role}${count.index >= var.node_count ? "-lb" : ""}-ip-${count.index >= var.node_count ? count.index - var.node_count : count.index}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.node.*.id, count.index)}" 
  }

  tags {
    environment = "${var.environment_name}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "node" {
  count                 = "${var.lb_node_count + var.node_count}"
  name                  = "${var.prefix}${var.role}${count.index >= var.node_count ? "-lb" : ""}-vm-${var.network_name}-${count.index >= var.node_count ? count.index - var.node_count : count.index}"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.node.*.id, count.index)}"]
  availability_set_id   = "${var.lb_node_count > 0 ? element(concat(azurerm_availability_set.node.*.id,list("")), 0) : ""}" 

  # 1 vCPU, 3.5 Gb of RAM
  vm_size = "${var.machine_type}"

  storage_os_disk {
    name              = "${var.prefix}${var.role}${count.index >= var.node_count ? "-lb" : ""}-disk-os-${var.network_name}-${count.index >= var.node_count ? count.index - var.node_count : count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
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
    computer_name  = "${var.role}${count.index >= var.node_count ? "-lb" : ""}-${count.index >= var.node_count ? count.index - var.node_count : count.index}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys = [
      {
        path     = "/home/${var.admin_username}/.ssh/authorized_keys"
        key_data = "${file(var.ssh_public_key)}"
      },
    ]
  }

  tags {
    environment = "${var.environment_name}"
    role        = "${var.role}"
  }
}


