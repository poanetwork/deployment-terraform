module "poa" {
    source = "./poa"

    resource_group_name = "${azurerm_resource_group.test.name}"
    subnet_id = "${azurerm_subnet.poa.id}"
    playbook_path = "${var.playbook_path}"
}
