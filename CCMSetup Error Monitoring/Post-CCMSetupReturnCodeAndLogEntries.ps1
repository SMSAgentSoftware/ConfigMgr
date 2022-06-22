###################################################################
## Intune PR script to get ccmsetup installation return codes    ##
## and send the error codes and recent warning/error log entries ##
## to a Log Analytics workspace                                  ##
###################################################################

## VARIABLES ##
$WorkspaceID = "<WorkspaceID>" # WorkspaceID of the Log Analytics workspace
$PrimaryKey = "<PrimaryKey>" # Primary Key of the Log Analytics workspace
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


#region Functions
# Create the function to create the authorization signature
# ref https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api
Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

# Create the function to create and post the request
# ref https://docs.microsoft.com/en-us/azure/azure-monitor/logs/data-collector-api
Function Post-LogAnalyticsData($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $TimeStampField = ""
    $signature = Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    try {
        $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    }
    catch {
        $response = $_#.Exception.Response
    }
    
    return $response
}

# Function to get the Azure AD device Id
Function Get-AADDeviceID {
    $AADCert = (Get-ChildItem Cert:\Localmachine\MY | Where {$_.Issuer -match "CN=MS-Organization-Access"})
    If ($null -ne $AADCert)
    {
        return $AADCert.Subject.Replace('CN=','')
    }
    # try some other ways to get the AaddeviceId in case ther cert is missing somehow
    else 
    {
        $AadDeviceId = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\CCM" -Name AadDeviceId -ErrorAction SilentlyContinue | Select -ExpandProperty AadDeviceId
        If ($null -eq $AadDeviceId)
        {
            try 
            {
                $dsreg = dsregcmd /status
                $DeviceIdMatch = $dsreg | Select-String -SimpleMatch "DeviceId" 
                If ($DeviceIdMatch -eq 1)
                {
                    return $DeviceIdMatch.Line.Split()[-1]
                } 
            }
            catch {}
        }
        Else
        {
            return $AadDeviceId
        }
    }
}

# Function to return CCM log entries to PS objects
function Convert-CCMLogToObjectArray {
    Param ($LogPath,$LineCount = 500)

    # Custom class to define a log entry
    class LogEntry {
        [string]$LogText
        [datetime]$DateTime 
        [string]$component
        [string]$context 
        [int]$type
        [int]$thread 
        [string]$file
    }

    # Function to extract the content between two strings in a string
    function Extract-String {
        param($String,$SearchStringStart,$SearchStringEnd)
        $Length = $SearchStringStart.Length
        $StartIndex = $LogLine.IndexOf($SearchStringStart,0) + $Length
        $EndIndex = $LogLine.IndexOf($SearchStringEnd,$StartIndex)
        return $LogLine.Substring($StartIndex,($EndIndex - $StartIndex))
    }

    If (Test-Path $LogPath)
    {
        $LogContent = (Get-Content $LogPath -Raw) -split "<!"
        $LogEntries = [System.Collections.ArrayList]::new()
        foreach ($LogLine in ($LogContent | Select -Last $LineCount))
        {
            If ($LogLine.Length -gt 0)
            {
                $LogEntry = [LogEntry]::new()
                $LogEntry.LogText = Extract-String -String $LogLine -SearchStringStart '[LOG[' -SearchStringEnd ']LOG'
                $time = Extract-String -String $LogLine -SearchStringStart '<time="' -SearchStringEnd '"'
                $date = Extract-String -String $LogLine -SearchStringStart 'date="' -SearchStringEnd '"'
                $DateTimeString = $date + " " + $time.Split('.')[0]          
                $LogEntry.DateTime = [datetime]::ParseExact($DateTimeString,"MM-dd-yyyy HH:mm:ss",[System.Globalization.CultureInfo]::InvariantCulture)
                $LogEntry.component = Extract-String -String $LogLine -SearchStringStart 'component="' -SearchStringEnd '"'
                $LogEntry.context = Extract-String -String $LogLine -SearchStringStart 'context="' -SearchStringEnd '"'
                $LogEntry.type = Extract-String -String $LogLine -SearchStringStart 'type="' -SearchStringEnd '"'
                $LogEntry.thread = Extract-String -String $LogLine -SearchStringStart 'thread="' -SearchStringEnd '"'
                $LogEntry.file = Extract-String -String $LogLine -SearchStringStart 'file="' -SearchStringEnd '"'
                [void]$LogEntries.Add($LogEntry)
            }
        }
        return $LogEntries
    }
}
#endregion


#region MainScript
$LogPath = "$env:WinDir\ccmsetup\Logs\ccmsetup.log"
$ReturnCodeEntry = Convert-CCMLogToObjectArray -LogPath $LogPath -LineCount 5 | 
    where {$_.LogText -match "CcmSetup is exiting with return code" -or $_.Logtext -match "CcmSetup failed with error code"}
# If we have a return code
If ($ReturnCodeEntry)
{  
    # Create the returnCode object
    $AADDeviceID = Get-AADDeviceID
    $ReturnCodeObject = [PSCustomObject]@{
        ReturnCode = $ReturnCodeEntry.LogText.Split()[-1]
        Date = $ReturnCodeEntry.DateTime
        Age_Days = ([DateTime]::Now - $ReturnCodeEntry.DateTime).Days
        AADDeviceID = $AADDeviceID
        ComputerName = $env:COMPUTERNAME
    }
    $ReturnCodeJson = ConvertTo-Json $ReturnCodeObject -Compress

    # Post the json to LA workspace
    $Post1 = Post-LogAnalyticsData -customerId $WorkspaceID -sharedKey $PrimaryKey -body ([System.Text.Encoding]::UTF8.GetBytes($ReturnCodeJson)) -logType "CM_CCMSetupReturnCodes"
    $StatusCodes = "$($Post1.StatusCode)"

    # If return code is not success or reboot, send recent warning and error log entries
    If ($ReturnCodeObject.ReturnCode -notin (0,7))
    {
        # Create the log entries object
        $Log = Convert-CCMLogToObjectArray -LogPath $LogPath
        $WarningErrorEntries = $Log | Where {$_.type -notin @(0,1)}
        $LineNumber = 0
        $DateTime = Get-Date ([DateTime]::UtcNow) -Format "s" # DateTime is added as sometimes not all entries are ingested at the same time, so TimeGenerated in LA can be different
        foreach ($WarningErrorEntry in $WarningErrorEntries)
        {
            $LineNumber ++
            $WarningErrorEntry | Add-Member -MemberType NoteProperty -Name AADDeviceID -Value $AADDeviceID
            $WarningErrorEntry | Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
            $WarningErrorEntry | Add-Member -MemberType NoteProperty -Name LineNumber -Value $LineNumber
            $WarningErrorEntry | Add-Member -MemberType NoteProperty -Name DatePosted -Value $DateTime
        }
        $LogJson = ConvertTo-Json $WarningErrorEntries -Compress
        
        # Post the json to LA workspace
        $Post2 = Post-LogAnalyticsData -customerId $WorkspaceID -sharedKey $PrimaryKey -body ([System.Text.Encoding]::UTF8.GetBytes($LogJson)) -logType "CM_CCMSetupErrorLog"
        $StatusCodes = $StatusCodes + "  |  $($Post2.StatusCode)"
    }

    # Output status codes
    Write-Output $StatusCodes
}
else 
{
    # Create the returnCode object
    $AADDeviceID = Get-AADDeviceID
    $ReturnCodeObject = [PSCustomObject]@{
        ReturnCode = $null
        Date = [DateTime]::Now
        Age_Days = 0
        AADDeviceID = $AADDeviceID
        ComputerName = $env:COMPUTERNAME
    }
    $ReturnCodeJson = ConvertTo-Json $ReturnCodeObject -Compress

    # Post the json to LA workspace
    $Post = Post-LogAnalyticsData -customerId $WorkspaceID -sharedKey $PrimaryKey -body ([System.Text.Encoding]::UTF8.GetBytes($ReturnCodeJson)) -logType "CM_CCMSetupReturnCodes"

    # Output status code
    Write-Output $Post.StatusCode
}
#endregion