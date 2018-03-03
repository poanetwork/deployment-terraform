# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "bootnode" {
  source = "./poanetwork/modules/bootnode"

  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"

  network_name = "sokol"
  platform = "centos"
  role = "bootnode"

  node_admin_email = "admin@example.com"
  node_name = "fly"
}
