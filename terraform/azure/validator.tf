# Create public IP
resource "azurerm_public_ip" "validatorIp" {
    name                         = "${var.prefix}-validator-ip"
    location                     = "${var.region}"
    resource_group_name          = "${azurerm_resource_group.test.name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "validatorNIC" {
    name                      = "${var.prefix}-validator-NIC"
    location                  = "${var.region}"
    resource_group_name       = "${azurerm_resource_group.test.name}"
    network_security_group_id = "${azurerm_network_security_group.validator.id}"

    ip_configuration {
        name                          = "${var.prefix}-validator-ip"
        subnet_id                     = "${azurerm_subnet.poa.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.validatorIp.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "validator" {
    count = 1
    name                  = "${var.prefix}-validator"
    location              = "${var.region}"
    resource_group_name   = "${azurerm_resource_group.test.name}"
    network_interface_ids = ["${azurerm_network_interface.validatorNIC.id}"]
    # 1 vCPU, 3.5 Gb of RAM
    vm_size               = "${var.machine_type}"
    depends_on = ["local_file.inventory", "local_file.validator"]

    storage_os_disk {
        name              = "${var.prefix}-validator-disk"
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
        computer_name  = "validator"
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
        command = "cd ../.. && ansible-playbook deployment-playbooks/validator.yml"
    }

    tags {
        environment = "Terraform Demo"
    }
}
