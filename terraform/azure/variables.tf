# Provide the path to the public key used for authentication on the vm
variable ssh_public_key {
  default = "~/.ssh/id_rsa.pub"
}

# Ansible public key
variable ssh_public_key_ansible {
  default = "~/.ssh/id_poa-test.pub"
}

# Ansible private key
variable ssh_private_key_ansible {
  default = "~/.ssh/id_poa-test"
}

# The region where to create resources
variable region {
  default = "West US 2"
}

# Resource group name
variable resource_group_name {
  default = "test"
}

# Prefix allows you to make structured names for the resources
variable prefix {
  default = "tf"
}

# Machine size for bootnode
variable machine_type {
  default = "Standard_DS1_v2"
}

variable node_fullname {}

variable node_admin_email {}

variable netstat_server_url {}

variable netstat_server_secret {}

variable mining_keyfile {}

variable mining_address {}

variable mining_keypass {}

variable moc_keypass {}

variable moc_keyfile {}

# Playbooks folder: the path to start Ansible provisioner
variable playbook_path { }
