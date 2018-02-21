# Create public IP
resource "azurerm_public_ip" "nodeIp" {
    name                         = "${var.prefix}-nodeIp"
    location                     = "${var.region}"
    resource_group_name          = "${azurerm_resource_group.test.name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "nodeNIC" {
    name                      = "${var.prefix}-nodeNIC"
    location                  = "${var.region}"
    resource_group_name       = "${azurerm_resource_group.test.name}"
    network_security_group_id = "${azurerm_network_security_group.bootnode.id}"

    ip_configuration {
        name                          = "${var.prefix}-default"
        subnet_id                     = "${azurerm_subnet.default.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.nodeIp.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "bootnode" {
    count = 1
    name                  = "${var.prefix}-bootnode"
    location              = "${var.region}"
    resource_group_name   = "${azurerm_resource_group.test.name}"
    network_interface_ids = ["${azurerm_network_interface.nodeNIC.id}"]
    # 1 vCPU, 3.5 Gb of RAM
    vm_size               = "${var.machine_type}"
    depends_on = ["local_file.inventory", "local_file.admins", "local_file.bootnode"]

    storage_os_disk {
        name              = "${var.prefix}-default"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    # delete the OS disk automatically when deleting the VM
    delete_os_disk_on_termination = true

    os_profile {
        computer_name  = "bootnode"
        admin_username = "poa"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys = [
          {
              path     = "/home/poa/.ssh/authorized_keys"
              key_data = "${file(var.ssh_public_key)}"
          },
          {
              path     = "/home/poa/.ssh/authorized_keys"
              key_data = "${file(var.ssh_public_key_ansible)}"
          }
        ]
    }

    provisioner "local-exec" {
        command = "cd ../.. && ansible-playbook playbooks/site.yml"
    }

    tags {
        environment = "Terraform Demo"
    }
}
