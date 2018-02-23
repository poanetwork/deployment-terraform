# Template for initial configuration bash script
data "template_file" "hosts" {
  template = "${file("${path.module}/templates/hosts.tpl")}"

  vars {
    node_address = "${azurerm_public_ip.nodeIp.ip_address}"
    explorer_address = "${azurerm_public_ip.explorerIp.ip_address}"
    private_key = "${var.ssh_private_key_ansible}"
  }
}

resource "local_file" "inventory" {
  depends_on = ["azurerm_public_ip.nodeIp"]
  content = "${data.template_file.hosts.rendered}"
  filename = "${path.module}/../../hosts"
}

data "template_file" "group_vars" {
  template = "${file("${path.module}/templates/group_vars.tpl")}"

  vars {
    node_fullname = "${var.node_fullname}"
    node_admin_email = "${var.node_admin_email}"
    netstat_server_url = "${var.netstat_server_url}"
    netstat_server_secret = "${var.netstat_server_secret}"
  }
}

resource "local_file" "group_vars" {
  content = "${data.template_file.group_vars.rendered}"
  filename = "${path.module}/../../playbooks/group_vars/all"
}

resource "local_file" "admins" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../playbooks/files/admins.pub"
}

resource "local_file" "bootnode" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../playbooks/files/ssh_bootnode.pub"
}

resource "local_file" "explorer" {
  content = "${file("${var.ssh_public_key_ansible}")}"
  filename = "${path.module}/../../playbooks/files/ssh_explorer.pub"
}
