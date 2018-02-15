# Provide the path to the public key used for authentication on the vm
variable ssh_public_key {
  default = "~/.ssh/id_rsa.pub"
}

# Ansible public key
variable ssh_public_key_ansible {
  default = "~/.ssh/id_poa-test.pub"
}

# The region where to create resources
variable region {
  default = "West US 2"
}

# Prefix allows you to make structured names for the resources
variable prefix {
  default = "tf"
}
