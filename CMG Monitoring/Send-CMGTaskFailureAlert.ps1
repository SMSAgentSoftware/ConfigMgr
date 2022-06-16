Param($Message)
$ServiceConnectionPointName = '<My_SCP_Server_Name>'
# Email params
$EmailParams = @{
    To         = '<RecipientAddress>'
    From       = '<SenderAddress>'
    Smtpserver = '<My_Org>.mail.protection.outlook.com' # direct send
    Port       = 25
    Subject    = "CMG Maintenance Task Failure"
}

$Body = @"
<html>
<head></head>
<body>
The ConfigMgr Service Monitor reports a failed maintenance task on the Cloud Management Gateway:<br>
<b>$Message</b>
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