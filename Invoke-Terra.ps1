#Set-StrictMode -Version Latest
#####################################################
# Invoke-Terra
#####################################################
<#PSScriptInfo

.VERSION 0.2

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
	[Parameter(Mandatory=$false)] #Init,Plan,Apply,Full
	[string] $path = "",
	[Parameter(Mandatory=$false)] #Init,Plan,Apply,Full
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
	Write-Verbose "$PSScriptRoot\$PSScriptName $name $output $backendconfig $varfile called by:$PSCallingScript"
}
process {
	if (!$output) { $output = $name }

	$origpath = $path ? $path : "$(Get-Location)"
	if ($path) { Set-Location $path }
	if (@('full','init') -contains $mode)
	{
		$backendconfig = Get-ConfigFile 'tfbackend'
		# if (!$backendconfig -and (Test-Path "*.tfbackend*"))
		# {
		# 	if (Test-Path "*.tfbackend.user") { $backendconfig = ".tfbackend.user" } 
		# 	elseif (Test-Path ".tfbackend") { $backendconfig = ".tfbackend"}
		# }	
		if (!$backendconfig) {
			terraform.exe init
		} else {
			terraform.exe init -backend-config="$backendconfig"
		}
	}
	if (@('full','plan') -contains $mode)
	{
		$varfile = Get-ConfigFile 'tfvars'
		# if (!$varfile -and (Test-Path "*.tfvars*"))
		# {
		# 	if (Test-Path "*.tfvars.user") { $varfile = ".tfvars.user" } 
		# 	elseif (Test-Path ".tfvars") { $varfile = ".tfvars"}
		# }
		if (!$varfile) {
			terraform.exe plan -out="$output.tfplan"
		} else {
			terraform.exe plan -var-file="$varfile" -out="$output.tfplan"
		}
	}
	if (@('full','apply') -contains $mode)
	{
		terraform.exe apply "$output.tfplan"
	}
}
end {
	Write-Verbose "$PSScriptName $name $output $backendconfig $varfile end"
	if ($origpath -ne $path) { Set-Location $origpath }
}