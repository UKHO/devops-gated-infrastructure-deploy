# First Time Implementation Guide

To use the template you'll need to make two sets of changes:

- [Update the AzDO project](#update-the-azdo-project) with a service connection to this GitHub repository
- [Update the pipeline](#update-the-pipeline) with the resource reference to the repository and add the template with parameters.

## Update the AzDO project

Coming soon...

## Update the Pipeline

### Repository Reference

Reference this repository in your root `azure-pipelines.yml` file.

```yaml
resources:
  repositories:
    - repository: GatedInfrastructureDeploy
      type: github
      endpoint: UKHO
      name: UKHO/devops-gated-infrastructure-deploy
      ref: refs/tags/1.0.0
```

### Add Template Block

Add this template block to your pipeline and fill out the values that relate to your deployment. The template content is a series of `jobs`, therefore they need to be rooted under a `stage`.

```yaml
- stage: Deploy
  displayName: "Deploy"
  dependsOn: Build
  jobs:
    - template: template.yml@GatedInfrastructureDeploy
      parameters:
        AzDOEnvironmentName: "string"
        TFStateResourceGroupName: "string"
        TFStateStorageAccountName: "string"
        TFStateContainerName: "string"
        TFStateBlobName: "string"
        TerraformWorkspace: "string"
        TerraformArtifactConfigRelativePath: "string"
        TerraformArtifact: "string"
        JobsVariableMappings:
          name: variableValue
          group: variableGroupName
          template: absolute/path/to/variables-template.yml
        TerraformVariableMappings:
          TERRAFORM_VARIABLE: "VALUE" 
        TerraformOutputVariables: # optional
          POSSIBLE_TERRAFORM_OUTPUT_VARIABLE

    - job: Deploy Web App
```

### Configure Parameters

Consult the [Templates Parameters in Detail](template-parameters-in-detail.md) document for more details.