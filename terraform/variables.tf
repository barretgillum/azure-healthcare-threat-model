variable "subscription_id" {
  description = "Azure subscription ID used for deployment"
  type        = string
}

variable "location" {
  description = "Azure region for lab resources"
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "rg-healthcare-threatlab"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "vnet-healthcare-prod"
}