# Template for Gated Infrastructure Deploy

TL;DR: AzDO Pipeline Template wrapping terraform apply and plan with a manual verification step, aka gate, to give a chance to check resources to be destroyed are expected.

> [!WARNING]
> The terraform plan cannot foresee every possible circumstance and scenario when determining changes to the infrastructure, only the terraform apply will truly know what changes will be made. Always test in an development environment first before moving to production.

> [!IMPORTANT]
> This template does require a container being passed in that has both Terraform and Powershell on it, recommendation is [ukhydrographicoffice/terraform-powershell](https://hub.docker.com/r/ukhydrographicoffice/terraform-powershell).

For more information on how this template works, read [how does this template work](docs/how-does-this-template-work.md).

For a guide on how to implementing into a pipeline for the first time, see [first time implementation guide](docs/first-time-implementation-guide.md).

For a guide on how to migrate from the old repository to using this template, see [migrate from old repository](docs/migrate-from-old-repository.md).

For an example of template implementation in pipeline, see this [example](examples/pipeline.yml).
