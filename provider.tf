terraform {
required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "hcp" {}

provider "azurerm" {
  region = "${var.resource_group_location}"
  default_tags {
    tags = {
      owner               = "${var.NAME}"
      project             = "project-draco"
      terraform           = "true"
      environment         = "dev"
    }
  }    
}