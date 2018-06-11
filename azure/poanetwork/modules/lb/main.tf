###LOAD BALANCING

locals {
  opened_ports  = "${var.opened_ports_by_role[var.role]}"
}

# Create public IP for lb
resource "azurerm_public_ip" "node_lb" {
  count                        = "${var.lb_node_count > 0 ? 1 : 0}"
  name                         = "${var.prefix}${var.role}-ip-lb"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"

  tags {
    environment = "${var.environment_name}"
  }
}

resource "azurerm_lb" "node" {
  count               = "${var.lb_node_count > 0 ? 1 : 0}"
  name                = "${var.prefix}${var.role}-lb"
  resource_group_name = "${var.resource_group_name}"
  location            = "${var.region}"

  frontend_ip_configuration {
    name                          = "${var.prefix}${var.role}-lb"
    public_ip_address_id          = "${join("",azurerm_public_ip.node_lb.*.id)}"
  }
}

resource "azurerm_lb_backend_address_pool" "node" {
  count               = "${var.lb_node_count > 0 ? 1 : 0}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.node.id}"
  name                = "${var.prefix}${var.role}-BackEndAddressPool"
}

resource "azurerm_lb_probe" "node" {
  count               = "${ length(local.opened_ports) * (var.lb_node_count>0? 1 : 0)}"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.node.id}"
  name                = "${element(local.opened_ports, count.index)}"
  protocol            = "Tcp"
  port                = "${element(var.ports[element(local.opened_ports, count.index)], 2)}"
  interval_in_seconds = "5"
  number_of_probes    = "2"
}

resource "azurerm_lb_rule" "node" {
  count                          = "${ length(local.opened_ports) * (var.lb_node_count > 0 ? 1 : 0)}"
  resource_group_name            = "${var.resource_group_name}"
  loadbalancer_id                = "${azurerm_lb.node.id}"
  name                           = "${element(local.opened_ports, count.index)}"
  protocol                       = "${element(var.ports[element(local.opened_ports, count.index)], 1)}"
  frontend_port                  = "${element(var.ports[element(local.opened_ports, count.index)], 0)}"
  backend_port                   = "${element(var.ports[element(local.opened_ports, count.index)], 2)}"
  frontend_ip_configuration_name = "${var.prefix}${var.role}-lb"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.node.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${element(azurerm_lb_probe.node.*.id,count.index)}"
  depends_on                     = ["azurerm_lb_probe.node"]
}