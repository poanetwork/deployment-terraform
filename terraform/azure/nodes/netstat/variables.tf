# Prefix allows you to make structured names for the resources
variable prefix {
  default = "tf"
}

# The region where to create resources
variable region {
  default = "West US 2"
}

# Resource group where netstat node lives
variable resource_group_name { }

# Subnet ID
variable subnet_id {}

# Machine size
variable machine_type {
  default = "Standard_DS1_v2"
}

# Provide the path to the public key used for authentication on the vm
variable ssh_public_key {
  default = "~/.ssh/id_rsa.pub"
}

# Ansible public key
variable ssh_public_key_ansible {
  default = "~/.ssh/id_poa-test.pub"
}

# Playbooks folder: the path to start Ansible provisioner
variable playbook_path { }

# Environment tag value
variable env_tag {
  default = "Terraform Demo"
}
