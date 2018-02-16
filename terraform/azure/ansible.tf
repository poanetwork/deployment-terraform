# Template for initial configuration bash script
data "template_file" "hosts" {
  template = "${file("${path.module}/hosts.tpl")}"

  vars {
    node_address = "${azurerm_public_ip.nodeIp.ip_address}"
  }
}

resource "local_file" "inventory" {
  depends_on = ["azurerm_public_ip.nodeIp"]
  content = "${data.template_file.hosts.rendered}"
  filename = "${path.module}/../../hosts"
}
