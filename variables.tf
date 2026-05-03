variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}
 
variable "resource_group_name" {
  type    = string
  default = "az-lab-ad-rg"
}
 
variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}
 
variable "admin_username" {
  type = string
}
 
variable "admin_password" {
  type      = string
  sensitive = true
}
 
variable "my_ip_address" {
  description = "Your public IP in CIDR notation — e.g. 203.0.113.42/32"
  type        = string
}
