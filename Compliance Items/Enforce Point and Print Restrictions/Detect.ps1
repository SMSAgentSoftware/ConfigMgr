$RegKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint"
$RegValues = Get-Item $RegKey -ErrorAction SilentlyContinue
If ($null -eq $RegValues)
{
    Write-host "Compliant"
}
else 
{
    try 
    {
        $NoWarningNoElevationOnInstall = $RegValues.GetValue('NoWarningNoElevationOnInstall')
        $UpdatePromptSettings = $RegValues.GetValue('UpdatePromptSettings')
    }
    catch {}
    If (($null -eq $NoWarningNoElevationOnInstall -or $NoWarningNoElevationOnInstall -eq 0) -and ($null -eq $UpdatePromptSettings -or $UpdatePromptSettings -eq 0))
    {
        Write-Host "Compliant"
    }
    else 
    {
        Write-Host "Not compliant"    
    }
    
}