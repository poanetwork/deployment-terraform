# Configure the Azure Provider
provider "azurerm" {
  version = "1.1.2"
}

module "common" {
  source = "./poanetwork/modules/common"
}

module "moc" {
  source = "./poanetwork/modules/node"

  resource_group_name = "${module.common.resource_group_name}"
  subnet_id = "${module.common.subnet_id}"

  network_name = "sokol"
  platform = "ubuntu"
  role = "moc"

  config = [
    "moc_keypass: 'secret'",
    "moc_keyfile: '~/.ssh/id_poa-test.pub'"
  ]
}
