# Configure the Azure Provider
provider "azurerm" { }

# Create resource group

resource "azurerm_resource_group" "test" {
  name     = "${var.prefix}-${var.resource_group_name}"
  location = "${var.region}"

  tags {
    environment = "Terraform Demo"
  }
}
