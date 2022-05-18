#Set-StrictMode -Version Latest
#####################################################
# Invoke-Terra
#####################################################
<#PSScriptInfo

.VERSION 0.13

.GUID 4eb31ea2-dbfd-4d66-9f6d-1d16ce6187d0

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell sitecore package

.LICENSEURI https://github.com/SharedSitecore/Invoke-Terra/blob/main/LICENSE

.PROJECTURI https://github.com/SharedSitecore/Invoke-Terra

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
see README.md
#>

<# 

.DESCRIPTION 
 PowerShell Script to Invoke-Terra

.PARAMETER name
Path of package

#> 
#####################################################
# Invoke-Terra
#####################################################
[CmdletBinding(SupportsShouldProcess)]
Param(
	[Parameter(Mandatory=$false)]
	[string] $path = '',
	[Parameter(Mandatory=$false)] #Default/Full,Clean,Init,Plan,Apply
	[string] $mode = 'full',
	[Parameter(Mandatory=$false)]
	[string] $name = 'main',
	[Parameter(Mandatory=$false)]
	[string] $output = '',
	[Parameter(Mandatory=$false)]
	[string] $backendconfig = '',
	[Parameter(Mandatory=$false)]
	[string] $varfile = '',
	[Parameter(Mandatory=$false)]
	[string] $options = '-compact-warnings'
)
begin {
	$ProgressPreference = "SilentlyContinue"		
	$ErrorActionPreference = 'Stop'
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose "$PSScriptRoot\$PSScriptName $path $mode $name $output $backendconfig $varfile $options called by:$PSCallingScript"
	Install-Script Get-ConfigFile -Force
}
process {
	if (!$output) { $output = $name }
	$origpath = $(Get-Location)
	if ($path) {
		Write-Verbose "Get-Location: $origpath"
		Write-Verbose "Set-Location: $path"
		Set-Location $path
	}
	Write-Verbose "mode: $mode"
	if ($mode -eq "clean") {
		Write-Verbose "cleaning"
		remove-item *.tfplan -ErrorAction "SilentlyContinue"
		remove-item terraform.tfstate -ErrorAction "SilentlyContinue"
		remove-item *.terraform* -Recurse -ErrorAction "SilentlyContinue"
	}
	$error.Clear()	
	if (@('clean','full','init') -contains $mode) {
		Write-Verbose "init"
		$backendconfig = Get-ConfigFile 'tfbackend'
		Write-Verbose "backendconfig:$backendconfig"
		if (!$backendconfig) {
			./terraform.exe init
		} else {
			./terraform.exe init -backend-config="$backendconfig"
		}
	}
	if ($error) {
		Write-Verbose "$PSScriptName ERROR: $error"
	} else {
		Write-Verbose "plan"
		if (@('clean','full','plan') -contains $mode) {
			$varfile = Get-ConfigFile 'tfvars'
			Write-Verbose "varfile:$varfile"
			if (!$varfile) {
				./terraform.exe plan -out="$output.tfplan"
			} else {
				if (!$options) {
					./terraform.exe plan -var-file="$varfile" -out="$output.tfplan"				
				} else {
					./terraform.exe plan -var-file="$varfile" $options -out="$output.tfplan"
				}
				Write-Verbose "plan completed:$output.tfplan exists:${(Test-Path "$output.tfplan")}"
			}
		}
		if ($error) {

			#needs init error? then do init!

			Write-Verbose "$PSScriptName ERROR: $error"
		} else {
			if (@('clean','full','apply') -contains $mode)
			{
				if (Test-Path "$output.tfplan") {
					Write-Verbose "apply"
					if (!$varfile) {
						./terraform.exe apply "$output.tfplan"
					} else {
						if (!$options) {
							./terraform.exe apply "$output.tfplan"
						} else {
							./terraform.exe apply $options "$output.tfplan" 
						}
					}
				} else {
					Write-Verbose "ERROR - $output.tfplan not found!"
					Write-Output "ERROR - $output.tfplan not found!"
				}
			}
			
			if ($error) {

				#if needs plan then do it!

				Write-Verbose "$PSScriptName ERROR: $error"
			}
		}
	}
}
end {
	Write-Verbose "$PSScriptName $path $mode $name $output $backendconfig $varfile $options end"
	if ($origpath -ne $path) { Set-Location $origpath }
}