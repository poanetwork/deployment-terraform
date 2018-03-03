# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "validator" {
  source = "./poanetwork/modules/node"

  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"

  network_name = "sokol"
  platform = "ubuntu"
  role = "validator"

  config = [
    "allow_validator_ssh: true",
    "allow_validator_p2p: true",
    "mining_keyfile: ~/.ssh/id_poa-test.pub",
    "mining_address: 0xABC",
    "mining_keypass: secret"
  ]
}
