# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "bootnode" {
  source = "./poanetwork/modules/bootnode"

  # Shared infrastructure
  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"

  # Network
  network_name = "sokol"

  # Platform the node is running on: centos or ubuntu
  platform = "centos"

  # Node specific configuration
  node_admin_email = "admin@example.com"
  node_name = "fly"
}
