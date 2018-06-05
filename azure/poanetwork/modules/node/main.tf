# Create public IP
resource "azurerm_public_ip" "node" {
  count                        = "${var.node_count}"
  name                         = "${var.prefix}${var.role}-ip-${count.index}"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "${var.environment_name}"
  }
}
/*
resource "azurerm_availability_set" "node" {
  name                = "BootnodeAvailabilitySet"
  count               = "${var.lb_node_count}>0? 1 : 0"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  tags {
    environment = "${var.environment_name}"
  }
}
*/
locals {
  opened_ports = "${var.opened_ports_by_role[var.role]}"
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

resource "azurerm_network_security_rule" "SSH" {
  count                       = "${contains( local.opened_ports, "ssh") ? 1 : 0 }"
  name                        = "SSH"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "HTTPS" {
  count                       = "${contains(local.opened_ports, "https") ? 1 : 0}"
  name                        = "HTTPS"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "RPC" {
  count                       = "${contains(local.opened_ports, "rpc") ? 1 : 0}"
  name                        = "RPC"
  priority                    = 1003
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "8545"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "P2P-TCP" {
  count                       = "${contains(local.opened_ports, "p2p") ? 1 : 0}"
  name                        = "P2P-TCP"
  priority                    = 1004
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "30303"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "P2P-UDP" {
  count                       = "${contains(local.opened_ports, "p2p") ? 1 : 0}"
  name                        = "P2P-UDP"
  priority                    = 1005
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "udp"
  source_port_range           = "*"
  destination_port_range      = "30303"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

resource "azurerm_network_security_rule" "HTTP-3000" {
  count                       = "${contains(local.opened_ports, "http-3000") ? 1 : 0}"
  name                        = "HTTP-3000"
  priority                    = 1006
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = "${var.resource_group_name}"
  network_security_group_name = "${azurerm_network_security_group.node.name}"
}

# Create network interface
resource "azurerm_network_interface" "node" {
  count                     = "${var.node_count}"
  name                      = "${var.prefix}${var.role}-network-card-count-${count.index}"
  location                  = "${var.region}"
  resource_group_name       = "${var.resource_group_name}"
  #network_security_group_id = "${azurerm_network_security_group.node.id}"

  ip_configuration {
    name                          = "${var.prefix}${var.role}-ip-${count.index}"
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
  count                 = "${var.node_count}"
  name                  = "${var.prefix}${var.role}-vm-${var.network_name}-${count.index}"
  location              = "${var.region}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.node.*.id, count.index)}"]
  #availability_set_id   = "${element(azurerm_availability_set.node.*.id, count.index)}" 

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
    computer_name  = "${var.role}-${count.index}"
    admin_username = "poa"
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
    countable_role = "${var.role}-${count.index}"
  }
}


###LOAD BALANCING
/*
resource "azurerm_lb" "node" {
  name                = "${var.prefix}-lb"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.region}"

  frontend_ip_configuration {
    name                          = "bootnode-lb"
    public_ip_address_id          = "${var.type == "public" ? join("",azurerm_public_ip.node.*.id) : ""}"
    subnet_id                     = "${var.subnet_id}"
  }
}

resource "azurerm_lb_backend_address_pool" "node" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.node.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "node" {
  count                          = "${length(var.remote_port)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.node.id}"
  name                           = "VM-${var.role}-${count.index}"
  protocol                       = "tcp"
  frontend_port                  = "${element(var.remote_port["${element(keys(var.remote_port), count.index)}"], 1)}"
  backend_port                   = "${element(var.remote_port["${element(keys(var.remote_port), count.index)}"], 1)}"
  frontend_ip_configuration_name = "${var.frontend_name}"
}

resource "azurerm_lb_probe" "node" {
  count               = "${length(var.lb_port)}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.node.id}"
  name                = "${element(keys(var.lb_port), count.index)}"
  protocol            = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  port                = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
  interval_in_seconds = "${var.lb_probe_interval}"
  number_of_probes    = "${var.lb_probe_unhealthy_threshold}"
}

resource "azurerm_lb_rule" "node" {
  count                          = "${length(var.lb_port)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.node.id}"
  name                           = "${element(keys(var.lb_port), count.index)}"
  protocol                       = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 1)}"
  frontend_port                  = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 0)}"
  backend_port                   = "${element(var.lb_port["${element(keys(var.lb_port), count.index)}"], 2)}"
  frontend_ip_configuration_name = "${var.frontend_name}"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.node.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${element(azurerm_lb_probe.node.*.id,count.index)}"
  depends_on                     = ["azurerm_lb_probe.node"]
}*/