# ref-arch-predefined-subnet-issue-repro
Reproduction of the issue described at https://github.com/tomtom-internal/reference-architecture/issues/39

## Steps to reproduce

This was tested with **Terraform v0.15.5**

This module only requires the `subscription_id` variable as input.

1. Run `terraform init -reconfigure -backend=true -backend-config=<provide your backend configuration>`
2. Run `terraform apply` for the first time. This will create the following resources:
   1. `module.networking.azurerm_vnet.vnet` to host the pre-defined subnet
   2. `module.networking.azurerm_subnet.subnet` as the pre-defined subnet to use
   3. `module.networking.azurerm_storage_account.example` as an example of an extraneous resource whose modifications impact the whole module
   4. `module.aks.reference_architecture.*` [v2.7.0 of the reference-architecture `azure/aks` module](https://github.com/tomtom-internal/reference-architecture/tree/v2.7.0/azure/aks)
3. After the modules have successfully applied, make a modification to the `module.networking.azurerm_storage_account.example` resource (e.g. changing the name)
4. Run `terraform apply` again

You should see that the `azurerm_kubernetes_cluster` resource needs to be re-created due to the fact that the `predefined_subnet.subnet.id`
value used for the `vnet_subnet_id` value of the cluster needs to be calculated during the same planning phase as the cluster itself.

Therefore it can not be deterministically calculated, and given the Note in the [documentation for this variable](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool#vnet_subnet_id)
this results in the cluster being forced to renew entirely.

## Example output

An example output of the second `terraform apply` run can be found in the [output folder](./output).

Lines 12, 185 and 350 indicate this particular issue.

However, it extends to any value that is read from a `data` source, that is managed by an upstream module,
which can not be determined during the planning phase of the Terraform lifecycle