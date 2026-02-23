variable "subscription_id" {
  description = "Azure subscription ID (from 'az account show' -> id)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "francecentral"
}

variable "prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "tp-dev-bsi"
}

variable "ssh_public_key" {
  description = "SSH public key for VMs"
  type        = string
}