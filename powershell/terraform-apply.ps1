param (
  [Parameter(Mandatory)]
  [ValidateScript({
      if (-not(Test-Path -Path $_ -PathType 'Container')) {
        throw "The directory path '$_' does not exist."
      }
      $true
    })]
  [string] $TerraformFilesDirectory,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TFStateResourceGroupName,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TFStateStorageAccountName,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TFStateContainerName,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TFStateBlobName,

  [string] $Workspace,

  [string] $TerraformOutputVariables = $env:GATED_DEPLOY_TERRAFORM_OUTPUT_VARIABLES,

  [string] $TFVarFiles = $env:GATED_DEPLOY_TFVAR_FILES
)

. $(Join-Path $PSScriptRoot "terraform-cmdlets.ps1")

SetLocationAndOutputInformation -Directory $TerraformFilesDirectory
Terraform-Init -TFStateResourceGroupName $TFStateResourceGroupName -TFStateStorageAccountName $TFStateStorageAccountName -TFStateContainerName $TFStateContainerName -TFStateBlobName $TFStateBlobName
if($Workspace) { Terraform-Workspace -Workspace $Workspace }
Terraform-Apply -TFVarFiles $TFVarFiles
ExportRequiredTerraformOutputVariables -TerraformOutputVariables $TerraformOutputVariables