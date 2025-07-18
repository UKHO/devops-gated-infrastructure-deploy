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

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ManualVerificationMode,

    [string] $Workspace,

    [string[]] $TFVarFiles
)

. $(Join-Path $PSScriptRoot "terraform-cmdlets.ps1")

$terraformOutputFileName = "terraform_output.txt"

SetLocationAndOutputInformation -Directory $TerraformFilesDirectory
Terraform-Init -TFStateResourceGroupName $TFStateResourceGroupName -TFStateStorageAccountName $TFStateStorageAccountName -TFStateContainerName $TFStateContainerName -TFStateBlobName $TFStateBlobName
if($Workspace) { Terraform-Workspace -Workspace $Workspace }
Terraform-Validate
Terraform-Plan -TerraformOutputFileName $terraformOutputFileName -TFVarFiles $TFVarFiles
SetChangesDetectedAndNeedsManualVerification -ManualVerificationMode $ManualVerificationMode -TerraformOutputFileName $terraformOutputFileName