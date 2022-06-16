############
## PARAMS ##
############
$script:dataSource = '<MY_SQL_Box>' # ConfigMgr database server
$script:database = 'CM_XXX'# ConfigMgr database name
$ServiceConnectionPointName = '<My_SCP_Server_Name>'
$EmailParams = @{
    To         = '<RecipientAddress>'
    From       = '<SenderAddress>'
    Smtpserver = '<My_Org>.mail.protection.outlook.com' # direct send
    Port       = 25
    Subject    = "CMG Status alert"
}

# Function to get query SQL database
function Get-SQLData {
    param($Query)
    $connectionString = "Server=$dataSource;Database=$database;Integrated Security=SSPI;"
    $connection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $connection.ConnectionString = $connectionString
    $connection.Open()
    
    $command = $connection.CreateCommand()
    $command.CommandText = $Query
    $reader = $command.ExecuteReader()
    $table = New-Object -TypeName 'System.Data.DataTable'
    $table.Load($reader)
    
    # Close the connection
    $connection.Close()
    
    return $Table
}

# Run database query
$Query = "
select 
    Name,
    Description,
    State,
    Case 
        When State = 0 then 'Ready'
        When State = 1 then 'Provisioning'
        When State = 2 then 'Error'
        When State = 3 then 'PerformingMaintenance'
        When State = 4 then 'Starting'
        When State = 5 then 'Stopping'
        When State = 6 then 'Stopped'
        Else 'Unknown'
    End as 'State Description',
    StateDetails
 from Azure_Service
where ServiceType = 'CloudProxyService'
and State != 0
"

[array]$Data = Get-SQLData -Query $Query

If ($Data.count -ge 1)
{
    foreach ($item in $Data)
    {
        If ($item.State -eq 2)
        {
$Body = @"
<html>
<head></head>
<body>
The Cloud Management Gateway $($item.Name) ($($item.Description)) is in an error state. There may be an issue with the CMG service.
<p>
<b>Recommended action:</b>  Check the CloudMgr.log and the *CMGService.logs on $ServiceConnectionPointName at ..\SMS\Logs for more details.</p>
<p>
<b>Recommended action:</b>  Run the <b>Connection Analyzer</b> from the Console at <i>Administration > Cloud Services > Cloud Management Gateway</i> and restart the CMG service if necessary.</p>
<p>
<b>Recommended action:</b>  Check the health status of the VM scale set instances in the Azure portal.</p>
</body>
</html>
"@   
            Send-MailMessage @EmailParams -Body $Body -BodyAsHtml -Priority High
        }
        Else
        {
$Body = @"
<html>
<head></head>
<body>
The Cloud Management Gateway $($item.Name) ($($item.Description)) is currently in the <b>'$($item.'State Description')'</b> state.
</body>
</html>
"@   
            Send-MailMessage @EmailParams -Body $Body -BodyAsHtml
        }
    }
}