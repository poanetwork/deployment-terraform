module "bootnode" {
  source = "./modules/bootnode"

  resource_group_name = "${var.resource_group_name}"
  subnet_id = "${var.subnet_id}"
  playbook_path = "${var.playbook_path}"
}

module "netstat" {
  source = "./modules/netstat"

  resource_group_name = "${var.resource_group_name}"
  subnet_id = "${var.subnet_id}"
  playbook_path = "${var.playbook_path}"

  servers = 0
}
