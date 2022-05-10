#Set-StrictMode -Version Latest
#####################################################
# Invoke-Terra
#####################################################
<#PSScriptInfo

.VERSION 0.10

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
- 0.1 init
- 0.2 added mode: Full,Init,Plan,Apply
- 0.3 added path param
- 0.4 fixed paths and added $error checks
- 0.5 added mode: Clean
- 0.6 added -ErrorAction "SilentlyContinue" on remove-items and Write-Verbose
- 0.7 added clean to init
- 0.8 added -compact-warnings -input=false
- 0.9 added *.tfplan to clean
- 0.10 added test-path tfplan
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
	[string] $path = "",
	[Parameter(Mandatory=$false)] #Default/Full,Clean,Init,Plan,Apply
	[string] $mode = "full",
	[Parameter(Mandatory=$false)]
	[string] $name = "main",
	[Parameter(Mandatory=$false)]
	[string] $output = '',
	[Parameter(Mandatory=$false)]
	[string] $backendconfig = '',
	[Parameter(Mandatory=$false)]
	[string] $varfile = ''
)
begin {
	$ProgressPreference = "SilentlyContinue"		
	$ErrorActionPreference = 'Stop'
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose "$PSScriptRoot\$PSScriptName $path $mode $name $output $backendconfig $varfile called by:$PSCallingScript"
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
			terraform.exe init
		} else {
			terraform.exe init -backend-config="$backendconfig"
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
				terraform.exe plan -out="$output.tfplan"
			} else {
				Write-Verbose "varfile:$varfile"
				terraform.exe plan -var-file="$varfile" -out="$output.tfplan -compact-warnings -input=false"
			}
		}
		if ($error) {

			#needs init error? then do init!

			Write-Verbose "$PSScriptName ERROR: $error"
		} else {
			if (@('clean','full','apply') -contains $mode)
			{
				if (Test-Path "$output.tfplan") {
					terraform.exe apply "$output.tfplan"
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
	Write-Verbose "$PSScriptName $path $mode $name $output $backendconfig $varfile end"
	if ($origpath -ne $path) { Set-Location $origpath }
}