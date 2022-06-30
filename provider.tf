terraform {
required_providers {
    azurerm = {
      source = "app.terraform.io/hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "hcp" {}

provider "azurerm" {
  subscription_id = "${var.subscription_id}"
  tenant_id       = "${var.tenant_id}"
  features {} 
}