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

## Proposed solutions

This issue occurs because Terraform can not determine certain values until after a module has been applied.

In this case, an `id` field for the `modules.networking.azurerm_subnet` resource is generated on the server side,
therefore Terraform does not know whether it changed **before** the `apply` phase has completed.

However, due to the dependency graph between `modules.aks -> modules.networking`, this value needs to be known during the `plan` phase,
since we are referencing this value from the `data.azurerm_subnet.predefined_subnet` source.

Due to the discrepancy in server-side generation of the value, but client-side requirements, Terraform can not interpret the state
of this value, and safely assumes it might change whenever **any** value in the upstream module changes.

Because of its very strict requirements in the `modules.aks.reference_architecture.azure_kubernetes_cluster` resource definition,
any change to the `vnet_subnet_id` value forces a renewal of the entire cluster. This is defined, albeit vaguely, by the following note
in [the documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool#vnet_subnet_id):
> NOTE:
>
> At this time the vnet_subnet_id must be the same for all node pools in the cluster

and the fact that changes to a Node Pools affect the entire cluster, requiring recreation.

### Require concrete input from the users for these values

One way to alleviate this, is to require users to pass this `id` value directly from their own modules,
rather than reading it from a data source.

This requires the addition of an `id` field to the [`predefined_subnet` variable](https://github.com/tomtom-internal/reference-architecture/blob/d812c81ae0443a64d339c1e9995a9b92239998e6/azure/aks/variables.tf#L121)
where users are required to already provide the correct id.
This way, only when the ID changes, will the cluster (appropriately) be impacted.

This method should also apply to **any** value that is currently derived from a data source (constructed from user-input), that is
**essential** to the lifecycle of resources provided by the reference-architecture module, such as

- [`azurerm_resource_group.rg` data source](https://github.com/tomtom-internal/reference-architecture/blob/d812c81ae0443a64d339c1e9995a9b92239998e6/azure/aks/main.tf#L12), derived from the [`existing_resource_group_name` variable](https://github.com/tomtom-internal/reference-architecture/blob/d812c81ae0443a64d339c1e9995a9b92239998e6/azure/aks/variables.tf#L109)
  - Its output attribute `location` is used in the cluster definition, which is also an essential lifecycle-impacting variable