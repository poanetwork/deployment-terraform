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
