variable region {
  description = "The region where to create resources"
  default     = "West US 2"
}

variable prefix {
  description = "Prefix allows you to make structured names for the resources"
  default     = "tf-"
}

variable resource_group_name {
  description = "Resource group name. All created resources reside within this resource group"
  default     = "test"
}

variable environment_name {
  description = "Set the environment tag for all created resources"
  default     = "Terraform Demo"
}
