# Create public IP
resource "azurerm_public_ip" "node" {
  count                        = "${var.lb_node_count > 0 ? var.lb_node_count : var.node_count}"
  name                         = "${var.prefix}${var.role}-ip-${count.index}"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "${var.environment_name}"
  }
}

resource "azurerm_availability_set" "node" {
  name                = "${var.prefix}${var.role}AvailabilitySet"
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
  count               = "${var.lb_node_count > 0 ? 1 : (var.node_count > 0 ? 1 : 0)}"
  name                = "${var.prefix}${var.role}-security-group"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    environment = "${var.environment_name}"
  }
}

resource "azurerm_network_security_rule" "node" {
  count                       = "${length(local.opened_ports) * (var.lb_node_count > 0 ? 1 : (var.node_count > 0 ? 1 : 0))}"
  name                        = "${var.prefix}${var.role}-security-group-${element(local.opened_ports, count.index)}"
  priority                    = "100${count.index}"
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "${element(var.ports[element(local.opened_ports, count.index)], 1)}"
  source_port_range           = "*"
  destination_port_range      = "${element(var.ports[element(local.opened_ports, count.index)], 2)}"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.0.name}"
}

# Create network interface
resource "azurerm_network_interface" "node" {
  count                     = "${var.lb_node_count > 0 ? var.lb_node_count : var.node_count}"
  name                      = "${var.prefix}${var.role}-network-card-count-${count.index}"
  location                  = "${var.region}"
  resource_group_name       = "${var.resource_group_name}"
  network_security_group_id = "${azurerm_network_security_group.node.0.id}"

  ip_configuration {
    name                          = "${var.prefix}${var.role}-ip-${count.index}"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.node.*.id, count.index)}" 
#    load_balancer_backend_address_pools_ids = ["${var.azurerm_lb_backend_address_pool_id}"]
  }

  tags {
    environment = "${var.environment_name}"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "node" {
  count                 = "${var.lb_node_count > 0 ? var.lb_node_count : var.node_count}"
  name                  = "${var.prefix}${var.role}-vm-${var.network_name}-${count.index}"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.node.*.id, count.index)}"]
  availability_set_id   = "${join("", azurerm_availability_set.node.*.id)}" 

  # 1 vCPU, 3.5 Gb of RAM
  vm_size = "${var.machine_type}"

  storage_os_disk {
    name              = "${var.prefix}${var.role}-disk-os-${var.network_name}-${count.index}"
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
    computer_name  = "${var.role}-${var.lb_node_count > 0 ? 0 : count.index}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys = [
      {
        path     = "/home/poa/.ssh/authorized_keys"
        key_data = "${file(var.ssh_public_key)}"
      },
    ]
  }

  tags {
    environment = "${var.environment_name}"
    role        = "${var.role}"
  }
}


