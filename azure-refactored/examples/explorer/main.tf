# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "explorer" {
  source = "./poanetwork/modules/explorer"

  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"
}
