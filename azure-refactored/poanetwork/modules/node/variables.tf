variable region {
  description = "The region where to create resources"
  default = "West US 2"
}

variable prefix {
  description = "Prefix allows you to make structured names for the resources"
  default = "tf-"
}

variable resource_group_name {
  description = "Resource group name. All created resources reside within this resource group"
}

variable environment_name {
  description = "Set the environment tag for all created resources"
  default = "Terraform Demo"
}

variable subnet_id {
  description = "Subnet ID"
}

variable ssh_public_key_ansible {
  description = "Public SSH key to put on the virtual machine. Ansible will use it to connect."
  default = "~/.ssh/id_poa-test.pub"
}

variable machine_type {
  description = "Machine size for running bootnode"
  default = "Standard_DS1_v2"
}

variable ssh_public_key {
  description = "Public SSH key to put on the virtual machine. User will use it to connect."
  default = "~/.ssh/id_rsa.pub"
}

variable network_name {
  description = "Name of the network this node is connected to. May be 'core' or 'sokol'"
  default = "sokol"
}

variable platform {
  description = "Name of the virtual machine operation system. Currently supports `ubuntu` or `centos`"
  default = "ubuntu"
}

variable image_publisher {
  description = "Name of the company maintaining the image"
  default = {
    ubuntu = "Canonical"
    centos = "OpenLogic"
  }
}

variable image_offer {
  description = "Name of the Azure offer for the image"
  default = {
    ubuntu = "UbuntuServer"
    centos = "CentOS"
  }
}

variable image_version {
  description = "Version of the OS image"
  default = {
    ubuntu = "16.04.0-LTS"
    centos = "7.3"
  }
}

variable config {
  description = "Values that will be supplied as Ansible group variables"
  type = "list"
  default = []
}

variable ansible_path {
  description = "The directory you cloned `poanetworks/deployment-playbooks` to"
  default = "./deployment-playbooks"
}

variable role {
  description = "Role of the node"
}

variable opened_ports_by_role {
  description = "What ports should be opened on the node?"
  type = "map"
  default = {
    "bootnode"  = [ "ssh", "p2p", "rpc", "https" ],
    "explorer"  = [ "ssh", "p2p", "http-3000", "https" ],
    "validator" = [ "ssh", "p2p" ],
    "netstat"   = [ "ssh", "https", "http-3000"],
    "moc"       = [ "ssh", "p2p" ]
    }
}
