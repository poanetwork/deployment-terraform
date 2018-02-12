# Provide the path to the public key used for authentication on the vm
variable ssh_public_key {
  default = "~/.ssh/id_rsa.pub"
}

# The region where to create resources
variable region {
  default = "West US 2"
}
