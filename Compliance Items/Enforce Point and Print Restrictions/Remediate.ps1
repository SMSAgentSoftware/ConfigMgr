$RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
Set-ItemProperty -Path $RegKey -Name NoWarningNoElevationOnInstall -Value 0 -Force
Set-ItemProperty -Path $RegKey -Name UpdatePromptSettings -Value 0 -Force