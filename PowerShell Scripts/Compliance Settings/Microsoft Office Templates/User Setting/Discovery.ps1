###################################################
##                                               ##
## Custom Office Templates User Discovery Script ##
##                                               ##
###################################################


## Change History
##
## v1.0 (2017-02-27)  



########################
## USER-SET VARIABLES ##
########################

# Set the remote template path.  This is a common location that is accessible to everyone. 
$RemoteTemplatePath = "\\<FileServer>\remotefiles\OfficeTemplates\Providers"

# This prefix should be assigned to all Provider names and is used to determine the custom location the XML files are found locally
$ProviderPrefix = "<CompanyName>"

# Office versions we will work with. This is used to determine the Office path in the HKCU registry
$OfficeVersionKeys = @(
    "16.0", # Office 2016
    "15.0", # Office 2013
    "14.0" # Office 2010
)




##########################
## SCRIPT-SET VARIABLES ##
##########################

# Determine OS Architecture
$OSArch = Get-WmiObject -Class win32_operatingsystem | select -ExpandProperty OSArchitecture

# Get the provider names that exist in the remote location
Try
{
    [array]$Providers = (Get-ChildItem $RemoteTemplatePath -Directory -ErrorAction Stop).Name
}
Catch
{
    # If there is an error accessing the remote location (no network access for example), exit the script with no output
    Break
}

# This is the path to the Templates directory in the user's profile
$UserTemplatePath = "$env:APPDATA\Microsoft\Templates"

# This is the path to the custom folder we are using to store our XML files in the user's profile
$CustomUserTemplatePath = "$UserTemplatePath\$ProviderPrefix"

# Determine which Office version/s we have installed. If the "spotlight" branch exists, it should indicate that this version of office is installed and being used.
[array]$InstalledOfficeKeys = $null
$OfficeVersionKeys | Foreach {
    If (Test-Path "HKCU:\Software\Microsoft\Office\$_\Common\Spotlight")
    {
        $InstalledOfficeKeys += $_
    }
}

# Set the program files directory by architecture
If ($OSArch -eq "32-bit")
{
    $ProgramFiles = "Program Files"
    $Architecture = "x86"
}
If ($OSArch -eq "64-bit")
{
    $ProgramFiles = "Program Files (x86)"
    $Architecture = "x64"
}




##################
## SCRIPT START ##
##################


################################
## DIRECTORY EXISTENCE CHECKS ##
################################

# Check that the custom user template path exists
If (!(Test-Path "$CustomUserTemplatePath"))
{
    "Not-Compliant on custom user template path"
    Break
}



# Check that the XML subfolder exists
If (!(Test-Path "$CustomUserTemplatePath\XML"))
{
    "Not-Compliant on custom user template path XML directory"
    Break
}


# Check that all providers exist locally under the XML directory
Try
{
    [array]$LocalProviders = (Get-ChildItem "$CustomUserTemplatePath\XML" -Directory -ErrorAction Stop).Name
}
Catch
{ 
    "Not-Compliant on custom user template provider directories (none found or error)"
    Break
}

$Providers | foreach {
    
    $Provider = $_
    If ($LocalProviders -notcontains $Provider)
    {
        "Not-Compliant on existence of remote provider locally"
        Break
    }

}

# Check that no providers exist locally that do not exist remotely (cleanup)
$LocalProviders | foreach {

    $Provider = $_
    If ($Providers -notcontains $Provider)
    {
        "Not-Compliant on existence of local provider remotely"
        Break
    }

}



########################################
## XML FILE EXISTENCE AND HASH CHECKS ##
########################################

# Check that XML files exist for each provider
$Providers | foreach {

    $Provider = $_
    [array]$RemoteXMLFiles = (Get-ChildItem "$RemoteTemplatePath\$Provider\XML" -File -ErrorAction Stop).Name | where {$_ -match $Architecture} # create an array even though only 1 file should be returned as array is used for the cleanup
    [array]$LocalXMLFiles = (Get-ChildItem "$CustomUserTemplatePath\XML\$Provider" -File -ErrorAction Stop).Name

    # Check that the XML files that exist remotely also exist locally
    $RemoteXMLFiles | foreach {
        If ($LocalXMLFiles -notcontains $_)
        {
            "Not-Compliant on existence of remote XML file locally"
            Break
        }
    }

    # Check that the XML files that exist locally also exist remotely (cleanup)
    $LocalXMLFiles | foreach {
        If ($RemoteXMLFiles -notcontains $_)
        {
            "Not-Compliant on existence of local XML file remotely"
            Break
        }
    }

    # Check that the hash values match
    $RemoteXMLFiles | foreach {
        $File = $_
        $RemoteHash = (Get-FileHash -Path "$RemoteTemplatePath\$Provider\XML\$File").Hash
        $LocalHash = (Get-FileHash -Path "$CustomUserTemplatePath\XML\$Provider\$File").Hash

        If ($RemoteHash -ne $LocalHash)
        {
            "Not-Compliant on XML file hash match"
            Break
        }
    }

}



#########################
## REGISTRY KEY CHECKS ##
#########################

# Break if no installed office version detected in registry
If (!$InstalledOfficeKeys)
{
    "Not-Compliant on existence of installed office versions in registry"
    Break
}

# Loop throught each installed Office version
$InstalledOfficeKeys | foreach {

    $OfficeVersionCode = $_
    
    # Get the list of providers existing in the local registry
    Try
    {
        [array]$LocalRegistryProviders = (Get-ChildItem "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers" -ErrorAction Stop).PSChildName
    }
    Catch
    { 
        "Not-Compliant on existence of local registry providers (none found or error)"
        Break
    }

    # Check that each remote provider exists in the current user registry providers
    $Providers | foreach {

        If ($LocalRegistryProviders -notcontains $_)
        {
            "Not-Compliant on existence of remote registry provider locally"
            Break
        }

    }

    # Check that each local registry provider exists in the remote provider list (cleanup)
    $LocalRegistryProviders | foreach {

        If ($Providers -notcontains $_)
        {
            "Not-Compliant on existence of local registry provider remotely"
            Break
        }

    }
    
    # Loop through each provider
    $Providers | foreach {

        $Provider = $_

        # Get the correct XML file for this provider (filter by architecture)
        $RemoteXMLFile = (Get-ChildItem "$RemoteTemplatePath\$Provider\XML" -File -ErrorAction Stop).Name | where {$_ -match $Architecture}

        # Define what the ServiceURL value should be and find what it currently is
        #$CorrectServiceUrl = "$env:SystemDrive\\$ProgramFiles\\Microsoft Office\\Templates\\$Provider\\$RemoteXMLFile"
        $CorrectServiceUrl = "$CustomUserTemplatePath\XML\$Provider\$RemoteXMLFile"
        $ActualServiceURL = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers\$Provider" -Name ServiceURL -ErrorAction SilentlyContinue | Select -ExpandProperty ServiceURL
            
        # Check that the ServiceURL key exists
        If (!$ActualServiceURL)
        {
            "Not Compliant on existence of ServiceURL key"
            break
        }
            
        # Check that the ServiceURL is correct
        If ($ActualServiceURL -ne $CorrectServiceUrl)
        {
            "Not Compliant on ServiceURL key entry"
            break
        }

    }

}



#######################
## REPORT COMPLIANCE ##
#######################

"Compliant"