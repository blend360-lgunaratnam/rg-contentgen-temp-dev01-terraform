# Github Azure Cred setup

Creates the managed identity GitHub Actions authenticates as, its federated
credentials, and its role assignments.

**Applied manually, not by CI.** Run `terraform apply` here yourself, as an
account with Owner on the resource group. The pipeline identity holds only
Contributor, which cannot create role assignments — by design.

CI never applies this module, so **a merged change here has no effect until
someone runs it locally.** Apply in the same PR you merge it.