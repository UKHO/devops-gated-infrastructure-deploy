# Template Parameters in detail

Consult the table below for information regarding the parameters. Hyperlinks lead to more detailed sections for specific parameters.

| parameter                                                                   | Required | Type   | Description                                                                                                                                                                                                                                                                | 
|-----------------------------------------------------------------------------|----------|--------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| 
| AzDOEnvironmentName                                                         | Yes      | string | Environment name as defined in Azure DevOps                                                                                                                                                                                                                                |
| TFStateResourceGroupName                                                    | Yes      | string | Terraform state resource group                                                                                                                                                                                                                                             |
| TFStateStorageAccountName                                                   | Yes      | string | Terraform state storage account                                                                                                                                                                                                                                            |
| TFStateContainerName                                                        | Yes      | string | Terraform state container                                                                                                                                                                                                                                                  |
| TFStateBlobName                                                             | Yes      | string | Terraform state blob                                                                                                                                                                                                                                                       |
| [TerraformWorkspace](#TerraformWorkspace)                                   | Yes      | string | Terraform workspace                                                                                                                                                                                                                                                        |
| [TerraformArtifact](#TerraformArtifact)                                     | Yes      | string | Artifact containing your .tf files and any other supporting files for your deployment                                                                                                                                                                                      |
| [TerraformArtifactConfigRelativePath](#TerraformArtifactConfigRelativePath) | Yes      | string | Relative path to the .tf files inside your artifact                                                                                                                                                                                                                        |
| [JobsVariableMappings](#JobsVariableMappings)                               | No       | object | A key/value map of variables to be added to the templates jobs. Each key/value pair can either be: a normal variable, a variable group, or a variable template. Current limitation is that there can only be 1 group and 1 template defined otherwise it is duplicate key. |
| [TerraformVariableMappings](#TerraformVariableMappings)                     | Yes      | object | A key/value map of Terraform variables to be injected into the PowerShell runtime environment for Terraform to use                                                                                                                                                         |
| [TerraformOutputVariables](#TerraformOutputVariables)                       | No       | object | An array of Terraform output variables to be retrieved after the Terraform apply has completed                                                                                                                                                                             |

Parameters in detail:

## TerraformWorkspace

This value will be appended onto the blob name in the form `[TFStateBlobName]:[TerraformWorkspace]`, e.g. `terraform.deployment.tfplan:dev`

## TerraformArtifact

The files in the artifact will be used without modifying their contents. Your pipeline will need to include jobs to make any required modifications to your supporting files e.g. inserting configuration values, before publishing the artifact.

## TerraformArtifactConfigRelativePath

Inside the template, the full path to the configuration will be `$(Pipeline.Workspace)/[TerraformArtifact][TerraformArtifactConfigRelativePath]`. Include the trailing slash in the path.

Example 1: The artifact is named `tfartifact` and .tf files are in the root of the artifact. `TerraformArtifactConfigRelativePath` would be `/` and the concatenated path would be `$(Pipeline.Workspace)/tfartifact/`.

```
+-- azure.tf
+-- main.tf
+-- variables.tf
+-- output.tf
```

Example 2: The artifact is named 'buildartifact' and the .tf files are in a subfolder within the artifact. `TerraformArtifactConfigRelativePath` would be `terraform/` and the concatenated path would be `$(Pipeline.Workspace)/buildartifact/terraform/`.

```
+-- src
+-- ...
+-- terraform
|   +-- azure.tf
|   +-- main.tf
|   +-- variables.tf
|   +-- output.tf
```

## JobsVariableMappings

To give the jobs inside the template the full range of variables they need, this parameter can be set to be different types of variables:

- Name: A singular variable which is in the form of KEY/VALUE pair. An example would be: `environment: dev` which will be accessible as `$(environment)`.
- Template: A path to a yaml template specifying a variables block, this allows the template to pull in all the variables from the template. In order to use the template path, the full path will be required in this format:`${{variables['System.DefaultWorkingDirectory']}}/pipeline/infrastructure-pipeline/vars-dev-deploy.yml@self`. Both the prefix of `${{variables['System.DefaultWorkingDirectory']}}` and suffix `@self` are required to find the correct repository of code, while the middle portion must be from the repository root directory to the variables template file. An example would be: `template: ${{variables['variables['System.DefaultWorkingDirectory']}}/pipeline/infrastructure-pipeline/vars-dev-deploy.yml@self` which the variables content would be accessible via `$(VARIABLE)`.
- Group: A name of a variable group defined in Azure DevOps which contains KEY/VALUE pairs. An example would be: `group: SSO-Dev` which the variables content would be accessible via `$(VARIABLE)`.

Currently, both Template and Group can only be defined once.

See [AzDO YAML Pipeline: Variable Definition](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/variables?view=azure-pipelines) for additional information.

## TerraformVariableMappings

This parameter allows for the mapping of values from Azure DevOps variable groups to be passed to Terraform for environment variables, tfvars, etc.

```yaml
ARM_CLIENT_ID: $(TERRAFORM-CLIENT-ID)
ARM_CLIENT_SECRET: $(TERRAFORM-CLIENT-SECRET)
ARM_TENANT_ID: $(TERRAFORM-TENANT-ID)
ARM_SUBSCRIPTION_ID: $(TERRAFORM-SUBSCRIPTION-ID)
TF_VAR_allowed_ips: $(whiteListedIps)
TF_VAR_spoke_rg: $(spokeRG)
```

## TerraformOutputVariables

Fairly common to have Terraform output variables that are values passed back out of Terraform after infrastructure has been created or updated, such as connection strings. This parameter allows them to be exported out via the `"##vso[task.setvariable variable=[var_name];isoutput=true]$output"` syntax. These can subsequently be accessed in sequential jobs by the use of a variable in a variable block. Sequential jobs that rely on this variable will need to have a `dependsOn` to ensure that the `deployInfrastructure` job has completed before they proceed.

``` yaml
- deployment: deployService  
 displayName: "Deploy Service"  
 dependsOn:  
 - deployInfrastructure  
 condition: succeeded('deployInfrastructure')  
 variables:  
 - name: "WEB_APP_NAME"  
   value: $[dependencies.deployInfrastructure.outputs['deployInfrastructure.deployment.web_app_name']]
```