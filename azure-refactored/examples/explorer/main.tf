# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "explorer" {
  source = "./poanetwork/modules/node"

  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"

  network_name = "sokol"
  platform = "ubuntu"
  role = "explorer"

  config = [
    "allow_explorer_ssh: true",
    "allow_explorer_p2p: true",
    "allow_explorer_http: true"
  ]
}
