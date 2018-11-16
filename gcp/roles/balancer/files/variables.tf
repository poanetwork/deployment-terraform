variable region {
  description = "The region where to create resources"
  default     = "West US 2"
}

variable prefix {
  description = "Prefix allows you to make structured names for the resources"
  default     = "tf-"
}

variable ssl_cert {
  description = "SSL certificate to be used by Azure Gateway"
}

variable nodes_cert {
  description = "A certificate, that will be used by nodes"
}

variable password {
  description = "A password used when creating ssl_cert"
}

variable resource_group_name {
  description = "Resource group name. All created resources reside within this resource group"
}

variable lb_node_count {
  description = "How many balanced nodes to deploy (for bootnodes)"
  default     = 0
}

variable environment_name {
  description = "Set the environment tag for all created resources"
  default     = "Terraform Demo"
}

variable balanced_ips {
  description = "A list of ips, that is used by backend balanced nodes"
  type        = "list"
  default     = []
}

variable virtual_network {
  description = "Name of the VPC where balancer should be created"
}