function Terraform-Init {
  [CmdletBinding()]
  param (
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
    [string] $TFStateBlobName
  )

  $activity = "terraform init command execution"
  Write-Output "Starting $activity"

  terraform init -migrate-state -backend-config="resource_group_name=$TFStateResourceGroupName" `
    -backend-config="storage_account_name=$TFStateStorageAccountName" `
    -backend-config="container_name=$TFStateContainerName" `
    -backend-config="key=$TFStateBlobName"

  ThrowErrorIfCommandHadError -Activity $activity
  Write-Output "Finished $activity"
}

function ThrowErrorIfCommandHadError {
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Activity
  )
  if (!$?) {
    throw "Something went wrong during: $Activity"
  }
}

function SetLocationAndOutputInformation {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Directory
  )
  Set-Location $Directory
  Write-Host "Current Directory: $( Get-Location )"

  Write-Host "Directory Content:"
  Get-ChildItem -File | ForEach-Object { Write-Host $_ }

  Write-Host "Terraform Version:"
  terraform --version
}

function Terraform-Workspace {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $Workspace
  )
  $activity = "terraform Workspace '$Workspace' command execution"
  Write-Output "Starting $activity"

  $ErrorActionPreference = 'SilentlyContinue'     # new workspace command files if workspace already exist
  terraform workspace new $Workspace 2>&1 > $null # if error thrown, just means workspace exists for usage
  $ErrorActionPreference = 'Continue'             # if no workspace exists, then it will get created
  terraform workspace select $Workspace

  ThrowErrorIfCommandHadError -Activity $activity
  Write-Output "Finished $activity"
}

function Terraform-Validate {
  $activity = "terraform validation command execution"
  Write-Output "Starting $activity"

  terraform validate

  ThrowErrorIfCommandHadError -Activity $activity
  Write-Output "Finished $activity"
}

function Terraform-Plan {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $TerraformOutputFileName,

    [string[]] $TFVarFiles
  )

  $activity = "terraform plan command execution"
  Write-Output "Starting $activity"

  $planName = "tfplan"

  $tfVarFileArgs = "" 
  if ($TFVarFiles.Count -gt 0) { $tfVarFileArgs = GetTFVarFileArgs -TFVarFiles $TFVarFiles }

  Invoke-Expression "terraform plan -out $planName $TFVarFileArgs" | Tee-Object $TerraformOutputFileName

  if ($( Test-Path $planName ) -eq $false) {
    Write-Host -ForegroundColor Red "Terraform Plan '$planName' was not created. See directory content:"
    Get-ChildItem -File | ForEach-Object { Write-Host $_ }
  }

  ThrowErrorIfCommandHadError -Activity $activity
  Write-Output "Finished $activity"
}

function Terraform-Apply {
  [CmdletBinding()]
  param (
    [string[]] $TFVarFiles
  )

  $activity = "terraform apply command execution"
  Write-Output "Starting $activity"

  $tfVarFileArgs = "" 
  if ($TFVarFiles.Count -gt 0) { $tfVarFileArgs = GetTFVarFileArgs -TFVarFiles $TFVarFiles }

  Invoke-Expression "terraform apply -auto-approve $TFVarFileArgs"

  ThrowErrorIfCommandHadError -Activity $activity
  Write-Output "Finished $activity"
}

function ExportRequiredTerraformOutputVariables {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string] $TerraformOutputVariables
  )

  if (![string]::IsNullOrEmpty($TerraformOutputVariables)) {
    Write-Output "Exporting required variables for deployment"
    foreach ($terraformOutputVariable in $TerraformOutputVariables -split " ") {
      $activity = "Exporting '$terraformOutputVariable' variable from terraform output."

      Write-Host $activity

      $output = terraform output -raw $terraformOutputVariable
      ThrowErrorIfCommandHadError -Activity $activity

      Write-Host "##vso[task.setvariable variable=$terraformOutputVariable;isoutput=true]$output"
      Write-Host "Exported."
    }
    Write-Output "Required variables exported"
  }
  else {
    Write-Host "No variables defined for export in TerraformOutputVariables parameter."
  }
}

function SetChangesDetectedAndNeedsManualVerification {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $ManualVerificationMode,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string] $TerraformOutputFileName
  )

  if ($( Test-Path -Path $TerraformOutputFileName ) -eq $false) {
    Write-Host -ForegroundColor Red "Terraform Output File '$TerraformOutputFileName' was not created. See directory content:"
    Get-ChildItem -File | ForEach-Object { Write-Host $_ }
  }
  else {
    $terraformOutputFile = Get-Content -Path $TerraformOutputFileName

    if( $terraformOutputFile -match "no changes" )
    {
      Write-Host "Terraform plan indicates no changes"
      Write-Host "##vso[task.setvariable variable=changesDetected;isoutput=true]false"
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
    }
    else {
      Write-Host "##vso[task.setvariable variable=changesDetected;isoutput=true]true"

      if ($ManualVerificationMode -eq "HaltOnDestroy") {
        $numberOfOccurancesToIndicateDeletionOfResources = 2
        $totalDestroyLines = ($terraformOutputFile |
          Select-String -Pattern "destroy" -CaseSensitive |
          Where-Object { $_ -ne "" }).length

        if ($totalDestroyLines -ge $numberOfOccurancesToIndicateDeletionOfResources) {
          Write-Host "Terraform plan indicates resources will be destroyed. Please verify..."
          Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
        }
      }
      elseif ($ManualVerificationMode -eq "HaltOnAny")
      {
        Write-Host "Terraform plan indicates resources will be add, removed or changed. Please verify..."
        Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
      }
      else {
        Write-Host "Terraform plan indicates resources will be add, removed or changed. Manual verification is disabled and will be skipped..."
        Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
      }
    }
  }
}

function GetTFVarFileArgs {
  param (
    [Parameter(Mandatory)]
    [string[]] $TFVarFiles
  )

  $tfVarFileArgs = ''

  foreach ($TFVarFile in $TFVarFiles)
  {
      $tfVarFileArgs += "-var-file='$TFVarFile' "
  }

  return $tfVarFileArgs
}