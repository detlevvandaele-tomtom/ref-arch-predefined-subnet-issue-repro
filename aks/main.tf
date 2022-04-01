module "reference_architecture" {
  source = "git@github.com:tomtom-internal/reference-architecture.git//azure/aks?ref=v2.7.0"

  use_managed_identity = true

  location                     = var.location
  stack_name                   = var.stack_name
  existing_resource_group_name = var.rg_name

  service_cidr           = "11.0.0.0/16"
  dns_service_ip         = "11.0.0.10"
  enable_host_encryption = false
  use_predefined_subnet  = true
  predefined_subnet = {
    resource_group = var.subnet_rg
    vnet_name      = var.vnet_name
    subnet_name    = var.subnet_name
  }
  predefined_routetable_associate = false
  tags = {
    environment = "testing"
  }
}

