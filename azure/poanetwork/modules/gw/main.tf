# Create public IP for lb
resource "azurerm_public_ip" "node" {
  count                        = "${var.lb_node_count > 0 ? 1 : 0}"
  name                         = "${var.prefix}${var.role}-ip-lb"
  location                     = "${var.region}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "dynamic"

  tags {
    environment = "${var.environment_name}"
  }
}

resource "azurerm_application_gateway" "node" {
  count               = "${var.lb_node_count > 0 ? 1 : 0}"
  name                = "${var.prefix}${var.role}-gw"
  location            = "${var.region}"
  resource_group_name = "${var.resource_group_name}"

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = "${var.lb_node_count}"
  }

  gateway_ip_configuration {
    name      = "${var.prefix}${var.role}-gw"
    subnet_id = "${var.subnet_id}"
  }

  ssl_certificate {
    name     = "default"
    data     = "${ base64encode(var.ssl_cert) }"
    password = "${var.password}"
  }

  authentication_certificate {
    name = "node"
    data = "${var.nodes_cert}"
  }

  frontend_port {
    name = "https"
    port = "443"
  }

  frontend_ip_configuration {
    name                          = "default"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${join("",azurerm_public_ip.node.*.id)}"
  }

  backend_address_pool {
    name            = "${var.prefix}instances"
    ip_address_list = ["${var.balanced_ips}"]
  }

  probe {
    name                = "default"
    protocol            = "Https"
    path                = "/api/health"
    interval            = 5
    host                = "127.0.0.1"
    timeout             = 4
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name                  = "https"
    cookie_based_affinity = "Disabled"
    port                  = "443"
    protocol              = "Https"
    request_timeout       = 5
    probe_name            = "default"

    authentication_certificate {
      name = "node"
    }
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = "default"
    frontend_port_name             = "https"
    protocol                       = "Https"
    ssl_certificate_name           = "default"
  }

  request_routing_rule {
    name                       = "default"
    rule_type                  = "Basic"
    http_listener_name         = "https"
    backend_address_pool_name  = "${var.prefix}instances"
    backend_http_settings_name = "https"
  }
}