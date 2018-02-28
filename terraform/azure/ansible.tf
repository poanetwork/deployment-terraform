# Template for initial configuration bash script
data "template_file" "hosts" {
  template = "${file("${path.module}/templates/hosts.tpl")}"

  vars {
    node_address = "${module.bootnode.boot_node_ip}"
    validator_address = "${azurerm_public_ip.validatorIp.ip_address}"
    netstat_address = "${module.netstat.netstat_node_ip}"
    moc_address = "${azurerm_public_ip.mocIp.ip_address}"
    explorer_address = "${azurerm_public_ip.explorerIp.ip_address}"
    private_key = "${var.ssh_private_key_ansible}"
  }
}

resource "local_file" "inventory" {
  content = "${data.template_file.hosts.rendered}"
  filename = "${path.module}/../../deployment-playbooks/hosts"
}

data "template_file" "group_vars" {
  template = "${file("${path.module}/templates/group_vars.tpl")}"

  vars {
    node_fullname = "${var.node_fullname}"
    node_admin_email = "${var.node_admin_email}"
    netstat_server_url = "${var.netstat_server_url}"
    netstat_server_secret = "${var.netstat_server_secret}"
    moc_keypass = "${var.moc_keypass}"
    moc_keyfile = "${var.moc_keyfile}"
    mining_keyfile = "${var.mining_keyfile}"
    mining_address = "${var.mining_address}"
    mining_keypass = "${var.mining_keypass}"
  }
}

resource "local_file" "group_vars" {
  content = "${data.template_file.group_vars.rendered}"
  filename = "${path.module}/../../deployment-playbooks/group_vars/all"
}

resource "local_file" "admins" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../deployment-playbooks/files/admins.pub"
}

resource "local_file" "bootnode" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../deployment-playbooks/files/ssh_bootnode.pub"
}

resource "local_file" "validator" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../deployment-playbooks/files/ssh_validator.pub"
}

resource "local_file" "netstat" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../deployment-playbooks/files/ssh_netstat.pub"
}

resource "local_file" "moc" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../playbooks/files/ssh_moc.pub"
}

resource "local_file" "explorer" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../playbooks/files/ssh_explorer.pub"
}
