# Configure the Azure Provider
provider "azurerm" { }

# Use predefined resource group
data "azurerm_resource_group" "test" {
  name = "${var.resource_group_name}"
}
