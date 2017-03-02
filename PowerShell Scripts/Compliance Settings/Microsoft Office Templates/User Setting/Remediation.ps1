###################################################
##                                               ##
## Custom Office Templates User Discovery Script ##
##                                               ##
###################################################

                                           
## Change History
##
## v1.0 (2017-02-28)                                            



########################
## USER-SET VARIABLES ##
########################

# Set the remote template path.  This is a common location that is accessible to everyone. 
$RemoteTemplatePath = "\\<FileServer>\remotefiles\OfficeTemplates\Providers"

# This is the root folder in the local template path where all the template providers and files will be created (eg, company name)
$RootFolderName = "<CompanyName>"

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
[array]$Providers = (Get-ChildItem $RemoteTemplatePath -Directory -ErrorAction Stop).Name

# This is the path to the Templates directory in the user's profile
$UserTemplatePath = "$env:APPDATA\Microsoft\Templates"

# This is the path to the custom folder we are using to store our XML files in the user's profile
$CustomUserTemplatePath = "$UserTemplatePath\$RootFolderName"

# Determine which Office version/s we have installed
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
    $Architecture = "x86"
}
If ($OSArch -eq "64-bit")
{
    $Architecture = "x64"
}




##################
## SCRIPT START ##
##################


##################################
## DIRECTORY CREATION / CLEANUP ##
##################################

# Check that the custom user template path exists
If (!(Test-Path "$CustomUserTemplatePath"))
{
    New-Item -Path $UserTemplatePath -Name $RootFolderName -ItemType container -Force
}

# Check that the XML subfolder exists
If (!(Test-Path "$CustomUserTemplatePath\XML"))
{
    New-Item -Path $CustomUserTemplatePath -Name "XML" -ItemType container -Force
}

# Check that all providers exist locally under the XML directory
[array]$LocalProviders = (Get-ChildItem "$CustomUserTemplatePath\XML" -Directory -ErrorAction Stop).Name
$Providers | foreach {
    
    $Provider = $_
    If ($LocalProviders -notcontains $Provider)
    {
        New-Item -Path "$CustomUserTemplatePath\XML" -Name $Provider -ItemType container -Force
    }

}

# Check that no providers exist locally that do not exist remotely (cleanup)
If ($LocalProviders.Count -ne 0)
{
    $LocalProviders | foreach {
    
        $Provider = $_
        If ($Providers -notcontains $Provider)
        {
            Remove-Item -Path "$CustomUserTemplatePath\XML\$Provider" -Recurse -Force -Confirm:$false
        }
    
    }
}



#################################
## XML FILE CREATION / CLEANUP ##
#################################

# Check that XML files exist for each provider
$Providers | foreach {

    $Provider = $_
    [array]$RemoteXMLFiles = (Get-ChildItem "$RemoteTemplatePath\$Provider\XML" -File -ErrorAction Stop).Name | where {$_ -match $Architecture} # create an array even though only 1 file should be returned as array is used for the cleanup
    [array]$LocalXMLFiles = (Get-ChildItem "$CustomUserTemplatePath\XML\$Provider" -File -ErrorAction SilentlyContinue).Name

    # Check that the XML files that exist remotely also exist locally
    $RemoteXMLFiles | foreach {
        
        $RemoteXMLFile = $_
        
        If ($LocalXMLFiles -notcontains $RemoteXMLFile)
        {
            Copy-Item "$RemoteTemplatePath\$Provider\XML\$RemoteXMLFile" "$CustomUserTemplatePath\XML\$Provider" -Force
        }

        # Regenerate the content branch as the XML file has been added
        $InstalledOfficeKeys | foreach {

            $OfficeVersionCode = $_

            If (Test-Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content")
            {
                Remove-Item "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content" -Recurse -Force -Confirm:$false
            }

        }
    }

    # Check that the XML files that exist locally also exist remotely (cleanup)
    If ($LocalXMLFiles.Count -ne 0)
    {
        $LocalXMLFiles | foreach {
    
            $LocalXMLFile = $_
    
            If ($RemoteXMLFiles -notcontains $LocalXMLFile)
            {
                Remove-Item -Path "$CustomUserTemplatePath\XML\$Provider\$LocalXMLFile" -Force -Confirm:$false
            }
        }
    }

    # Check that the hash values match
    $RemoteXMLFiles | foreach {
        $File = $_
        $RemoteHash = (Get-FileHash -Path "$RemoteTemplatePath\$Provider\XML\$File").Hash
        $LocalHash = (Get-FileHash -Path "$CustomUserTemplatePath\XML\$Provider\$File").Hash

        If ($RemoteHash -ne $LocalHash)
        {
            Copy-Item "$RemoteTemplatePath\$Provider\XML\$File" "$CustomUserTemplatePath\XML\$Provider" -Force
            
            # Regenerate the content branch as the XML file has changed
            $InstalledOfficeKeys | foreach {

                $OfficeVersionCode = $_

                If (Test-Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content")
                {
                    Remove-Item "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content" -Recurse -Force -Confirm:$false
                }

            }
        }
    }
}




#####################################
## REGISTRY KEY CREATION / CLEANUP ##
#####################################


# Loop through each installed Office version
$InstalledOfficeKeys | foreach {

    $OfficeVersionCode = $_
    
    # Get the list of providers existing in the local registry
    [array]$LocalRegistryProviders = (Get-ChildItem "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers" -ErrorAction SilentlyContinue).PSChildName

    # Loop through the providers
    $Providers | foreach {
        
        $Provider = $_

        # Check that each remote provider exists in the current user registry providers and create the ServiceURL key where necessary
        $RemoteXMLFile = (Get-ChildItem "$RemoteTemplatePath\$Provider\XML" -File -ErrorAction Stop).Name | where {$_ -match $Architecture}
        $ServiceURLDefinition = "$CustomUserTemplatePath\XML\$Provider\$RemoteXMLFile"
        If ($LocalRegistryProviders -notcontains $Provider)
        {
            New-Item -Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers" -Name $Provider -Force
            New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers\$Provider" -Name ServiceURL -Value $ServiceURLDefinition -Force
            
            # Regenerate the content branch as a new XML has been added
            If (Test-Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content")
            {
                Remove-Item "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content" -Recurse -Force -Confirm:$false
            }
        }

        # Check that the ServiceURL key is correct
        $ActualServiceURL = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers\$Provider" -Name ServiceURL -ErrorAction SilentlyContinue | Select -ExpandProperty ServiceURL
        If ($ActualServiceURL -ne $ServiceURLDefinition)
        {
            New-ItemProperty -Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers\$Provider" -Name ServiceURL -Value $ServiceURLDefinition -Force
            
            # Regenerate the content branch as the XML file may be new
            If (Test-Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content")
            {
                Remove-Item "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content" -Recurse -Force -Confirm:$false
            }
        }
    }

    # Loop through the local providers in the registry
    $LocalRegistryProviders | foreach {

        $Provider = $_
        
        # Check that each local registry provider exists in the remote provider list (cleanup)
        If ($Providers -notcontains $Provider)
        {
            Remove-Item -Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Providers\$Provider" -Recurse -Force -Confirm:$false
            
            # Regenerate the content branch as a provider has been removed
            If (Test-Path "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content")
            {
                Remove-Item "HKCU:\Software\Microsoft\Office\$OfficeVersionCode\Common\Spotlight\Content" -Recurse -Force -Confirm:$false
            }
        }

    }
    
}
