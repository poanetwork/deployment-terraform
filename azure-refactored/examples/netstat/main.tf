# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "netstat" {
  source = "./poanetwork/modules/node"

  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"

  network_name = "sokol"
  platform = "ubuntu"
  role = "netstat"

  config = [
    "allow_netstat_ssh: true",
    "allow_netstat_http: true",
    "netstats_secret: 'secret'"
  ]

}
