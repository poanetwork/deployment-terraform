# Create virtual network
resource "azurerm_virtual_network" "default" {
    name                = "${var.prefix}-default"
    address_space       = ["10.0.0.0/16"]
    location            = "${var.region}"
    resource_group_name = "${azurerm_resource_group.test.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "default" {
    name                 = "${var.prefix}-default"
    resource_group_name  = "${azurerm_resource_group.test.name}"
    virtual_network_name = "${azurerm_virtual_network.default.name}"
    address_prefix       = "10.0.1.0/24"
}
