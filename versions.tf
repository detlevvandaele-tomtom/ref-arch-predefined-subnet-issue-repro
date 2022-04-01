terraform {
  required_version = ">= 0.15.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.89.0, < 3.0.0"
    }
  }
}
