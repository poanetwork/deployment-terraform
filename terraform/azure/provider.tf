# Configure the Azure Provider
provider "azurerm" { }

# Use predefined resource group
data "azurerm_resource_group" "test" {
  name = "test-terraform"
}
