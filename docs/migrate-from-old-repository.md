# Migrate from old repository

This template used to be hosted in an internal private repository for AzDO Templates, to migrate to use it follow these sections.

## New repository resource block

If the pipeline is using other templates from the old repository then this repository will be added as an additional resource, while if no other templates are being used, the old resource block can be replaced.

Resource block:

```yaml
 - repository: GatedInfrastructureDeploy
   type: github
   endpoint: "UKHO" 
   name: UKHO/devops-gated-infrastructure-deploy
   ref: refs/tags/v1.0
```

## Update template reference

The old reference to the template is too verbose and can instead be updated to be: `template.yml@GatedInfrastructureDeploy`.

## Upgrade as needed

This guide was written on the pretense that migration from old to new would happen relatively quickly, therefore version 1 of this repository is documented in this guide. For future upgrades, see the [upgrade guide](upgrade-guide.md).