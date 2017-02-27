######################################################
##                                                  ##
## Custom Office Templates Machine Discovery Script ##
##                                                  ##
######################################################


## Change History
##
## v1.0 (2017-02-27) 



########################
## USER-SET VARIABLES ##
########################

# Set the remote template path.  This is a common location that is accessible to everyone. 
$RemoteTemplatePath = "\\<FileServer>\remotefiles\OfficeTemplates\Providers"

# This prefix should be assigned to all Provider names, to allow the exclusion of default directories in the local templates folder, such as 1033, Presentation designs etc.  Used for cleanup.
$ProviderPrefix = "<CompanyName>"




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

# Set local template path by architecture
If ($OSArch -eq "32-bit")
{
    $LocalTemplatePath = "$env:SystemDrive\Program Files\Microsoft Office\Templates"
}
If ($OSArch -eq "64-bit")
{
    $LocalTemplatePath = "$env:SystemDrive\Program Files (x86)\Microsoft Office\Templates"
}




#################
## MAIN SCRIPT ##
#################


# Check local template directory for any provider directories that have been removed in the remote location (cleanup)
[array]$LocalProviders = (Get-ChildItem $LocalTemplatePath -Directory).Name
$LocalProviders = $LocalProviders | where {$_ -match $ProviderPrefix}
$LocalProviders | foreach {
    If ($Providers -notcontains $_)
    {
        "Not-Compliant on local provider existing remotely"
        Break
    }
}


# Loop through each provider...
$Providers | Foreach {
    
    $Provider = $_

    ##############################
    ## PROVIDER DIRECTORY CHECK ##
    ##############################

    If (Test-Path -Path "$LocalTemplatePath\$Provider")
    { }
    Else
    {
        "Not-Compliant on remote provider existing locally"
        Break
    }


    ###############################
    ## SUBFOLDER DIRECTORY CHECK ##
    ###############################

    # Create an array of the subfolders found for this provider in the remote template directory
    Try
    {
        [array]$RemoteSubfolders = (Get-ChildItem "$RemoteTemplatePath\$Provider" -Exclude "XML" -Directory -ErrorAction Stop).Name
    }
    Catch
    {
        # If there is an error accessing the remote location (no network access for example), exit the loop
        Break
    }

    # Check Local subfolder to see if something is present that is not present in the remote location (cleanup)
    [array]$LocalSubfolders = (Get-ChildItem "$LocalTemplatePath\$Provider" -Exclude "XML" -Directory -ErrorAction Stop).Name
    If ($LocalSubfolders)
    {
        $LocalSubfolders | foreach {

            If ($RemoteSubfolders -notcontains $_)
            {
                "Not-Compliant on local subfolders existing remotely"
                Break
            }

        }
    }

    # For each remote subfolder...
    $RemoteSubfolders | foreach {
        
        $Subfolder = $_

        # Check that subfolder directory exists
        If (Test-Path -Path "$LocalTemplatePath\$Provider\$Subfolder")
        { }
        Else
        {
            "Not-Compliant on remote subfolders existing locally"
            Break
        }

    }


    ##########################
    ## TEMPLATE FILE CHECKS ##
    ##########################

    $RemoteSubfolders | foreach {
        
        $Subfolder = $_

        # Create an array of template filenames present in the REMOTE path
        Try
        {
            [array]$RemoteFileArray = (Get-ChildItem "$RemoteTemplatePath\$Provider\$Subfolder" -File).Name 
        }
        Catch
        {
            # If there is an error accessing the remote location (no network access for example), exit the loop
            Break
        }

        # Create an array of template filenames present in the LOCAL path
        [array]$LocalFileArray = (Get-ChildItem "$LocalTemplatePath\$Provider\$Subfolder" -File).Name 

        # Check each local file to see if it is present remotely (cleanup)
        If ($LocalFileArray)
        {
            $LocalFileArray | foreach {

                If ($RemoteFileArray -notcontains $_)
                {
                    "Not-Compliant on local file existing remotely"
                    Break
                }

            }
        }

        # Loop through each file in the remote template path
        $RemoteFileArray | foreach {
            
            ##############################
            ## TEMPLATE EXISTENCE CHECK ##
            ##############################
            
            # Check that the remote template file is present locally
            $File = $_
            If ($LocalFileArray)
            {
                If ($LocalFileArray -contains $File)
                { }
                Else
                {
                    "Not-Compliant on remote file existing locally"
                    Break
                }
            }


            ###############################
            ## TEMPLATE HASH MATCH CHECK ##
            ###############################

            # Check Hash
            $RemoteFileHash = (Get-FileHash -Path "$RemoteTemplatePath\$Provider\$Subfolder\$File").Hash
            $LocalFileHash = (Get-FileHash -Path "$LocalTemplatePath\$Provider\$Subfolder\$File").Hash
            If ($LocalFileHash)
            {
                If ($RemoteFileHash -eq $LocalFileHash)
                { }
                Else
                {
                    "Not-Compliant on hash match of local and remote file"
                    Break
                }
            }
        }
    }
}


#######################
## REPORT COMPLIANCE ##
#######################

Write-host "Compliant"