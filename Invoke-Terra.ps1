#Set-StrictMode -Version Latest
#####################################################
# Invoke-Terra
#####################################################
<#PSScriptInfo

.VERSION 0.16

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
	$ProgressPreference = 'SilentlyContinue'
	$Global:ErrorActionPreference = 'Stop'
	$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSScriptVersion = (Test-ScriptFileInfo -Path $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty Version)
	$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Host '#####################################################'
	Write-Host "# $PSScriptRoot/$PSScriptName $($PSScriptVersion) $path $mode $name $output $backendconfig $varfile $options called by:$PSCallingScript"
	Install-Script Get-ConfigFile -Repository PSGallery -Force
}
process {
	if (!$output) { $output = $name }
	$origpath = $(Get-Location)
	if ($path) {
		Write-Host "Get-Location: $origpath"
		Write-Host "Set-Location: $path"
		Set-Location $path
	}
	Write-Host "mode: $mode"
	if ($mode -eq "clean") {
		Write-Host "cleaning"
		remove-item *.tfplan -ErrorAction "SilentlyContinue"
		remove-item terraform.tfstate -ErrorAction "SilentlyContinue"
		remove-item *.terraform* -Recurse -ErrorAction "SilentlyContinue"
	}
	$error.Clear()	
	if (@('clean','full','init') -contains $mode) {
		Write-Host "init"
		$backendconfig = Get-ConfigFile 'tfbackend'
		Write-Host "backendconfig:$backendconfig"
		if (!$backendconfig) {
			./terraform.exe init
		} else {
			./terraform.exe init -backend-config="$backendconfig"
		}
	}
	if ($error) {
		Write-Host "$PSScriptName ERROR: $error"
	} else {
		Write-Host "plan"
		if (@('clean','full','plan') -contains $mode) {
			$varfile = Get-ConfigFile 'tfvars'
			Write-Host "varfile:$varfile"
			if (!$varfile) {
				./terraform.exe plan -out="$output.tfplan"
			} else {
				if (!$options) {
					./terraform.exe plan -var-file="$varfile" -out="$output.tfplan"				
				} else {
					./terraform.exe plan -var-file="$varfile" $options -out="$output.tfplan"
				}
				Write-Host "plan completed:$output.tfplan exists:${(Test-Path "$output.tfplan")}"
			}
		}
		if ($error -or !(Test-Path "$output.tfplan")) {

			#needs init error? then do init!

			Write-Host "$PSScriptName ERROR: $error or $output.tfplan not found"
		} else {
			if (@('clean','full','apply') -contains $mode)
			{
				Write-Host "apply"
				if (!$varfile) {
					./terraform.exe apply "$output.tfplan"
				} else {
					if (!$options) {
						./terraform.exe apply "$output.tfplan"
					} else {
						./terraform.exe apply $options "$output.tfplan" 
					}
				}
			}
			
			if ($error) {

				#if needs plan then do it!

				Write-Host "$PSScriptName ERROR: $error"
			}
		}
	}
}
end {
	Write-Host "$PSScriptName $path $mode $name $output $backendconfig $varfile $options end"
	if ($origpath -ne $path) { Set-Location $origpath }
}