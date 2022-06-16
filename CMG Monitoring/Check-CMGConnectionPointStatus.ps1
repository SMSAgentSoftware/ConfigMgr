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
    Subject    = "CMG Connection Point Status alert"
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
Select 
    ServerName,
    ProxyServiceName,
    ConnectionStatus,
    Case 
        When ConnectionStatus = 0 then 'All connections offline'
        When ConnectionStatus = 1 then 'Connections partially online'
        When ConnectionStatus = 2 then 'Connections all online'
        Else 'Unknown'
    End as 'ConnectionStatus Description'
 from vProxy_Connectors
 where ConnectionStatus != 2
"

[array]$Data = Get-SQLData -Query $Query

If ($Data.count -ge 1)
{
    foreach ($item in $Data)
    {
$Body = @"
<html>
<head></head>
<body>
The connection point '$($item.ServerName)' for the Cloud Management Gateway '$($item.ProxyServiceName)' is currently in the <b>'$($item.'ConnectionStatus Description')'</b> state. There may be an issue with the CMG service.
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
}