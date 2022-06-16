############
## PARAMS ##
############
[int]$CMGClientCountThreshold = 20 # The minimum number of CMG-connected clients before an alert is triggered
$script:dataSource = '<MY_SQL_Box>' # ConfigMgr database server
$script:database = 'CM_XXX'# ConfigMgr database name
$ServiceConnectionPointName = '<My_SCP_Server_Name>'
$EmailParams = @{
    To         = '<RecipientAddress>'
    From       = '<SenderAddress>'
    Smtpserver = '<My_Org>.mail.protection.outlook.com' # direct send
    Port       = 25
    Subject    = "Low CMG Client Count Alert"
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
Select top 1
sum(CMGOnlineClients) as 'CMGOnlineClients',Timestamp
from dbo.BGB_Statistics st
Group by [TimeStamp]
Order by [TimeStamp] desc
"
$Data = Get-SQLData -Query $Query

# Send alert email if count is low
If ($Data.CMGOnlineClients -le $CMGClientCountThreshold)
{
$Body = @"
<html>
<head></head>
<body>
The number of clients connecting to the Cloud Management Gateway is low ($($Data.CMGOnlineClients)). There may be an issue with the CMG service.
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