variable "resource_group_name_prefix" {
  default       = "rg"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "resource_group_location" {
  default       = "westeurope"
  description   = "Location of the resource group."
}

variable "subscription_id" {
  default       = "d7a81abe-a833-4e43-aec0-33c4798f5425"
  description   = "Subscription ID"
}

variable "tenant_id" {
  default       = "d6b5626c-0aea-421f-877f-25d40c2db90b"
  description   = "Tenant ID"
}

variable "NAME" {    
    default = "draco"
    description   = "Name"

}
