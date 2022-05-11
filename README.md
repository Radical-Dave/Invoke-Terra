# Invoke-Terra
## Description
PowerShell Helper to Invoke-Terra automatically finds backend config and tfvars files using Get-Config

## Installation (Powered by [PowerShellGallery](https://powershellgallery.com/packages/Invoke-Terra))
PS>
```ps
Install-Script Invoke-Terra
```

PS>
```ps
Install-Script -Name Invoke-Terra
```

## Example
PS> 
```ps
Invoke-Terra -help
```

PS>
```ps
Invoke-Terra
```

## Release Notes
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
- 0.11 added options

## Copyright
David Walker, [Radical Dave](https://github.com/radical-dave), [Sitecore Dave](https://github.com/sitecoredave)

## License
MIT License: https://github.com/Radical-Dave/Invoke-Terra/blob/main/LICENSE
