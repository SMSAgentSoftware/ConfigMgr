Try
{
    [datetime]$Date = (Get-ItemProperty -Path HKLM:\SOFTWARE\IT_Local\LocalAdminInfo -Name LastUpdated -ErrorAction Stop).LastUpdated
}
Catch
{
    "Error"
    Break
}

# If script was last run less than 15 minutes ago, report compliant
If ($Date -ge (Get-Date).AddMinutes(-15))
{
    "Compliant"
}
Else
{
    "Not-Compliant"  
}