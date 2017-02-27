########################################################
##                                                    ##
## Custom Office Templates Machine Remediation Script ##
##                                                    ##
########################################################


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
[array]$Providers = (Get-ChildItem $RemoteTemplatePath -Directory -ErrorAction Stop).Name

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

################################
## PROVIDER DIRECTORY CLEANUP ##
################################

# Check local template directory for any provider directories that have been removed in the remote location and remove them (cleanup)
[array]$LocalProviders = (Get-ChildItem $LocalTemplatePath -Directory).Name
$LocalProviders = $LocalProviders | where {$_ -match $ProviderPrefix}
$LocalProviders | foreach {
    
    $Provider = $_
    If ($Providers -notcontains $Provider)
    {
        "Removing Provider $LocalTemplatePath\$Provider recursively"
        Remove-Item -Path "$LocalTemplatePath\$Provider" -Recurse -Force
    }

}

# Loop through each provider...
$Providers | Foreach {
    
    $Provider = $_

    #################################
    ## PROVIDER DIRECTORY CREATION ##
    #################################

    If (!(Test-Path -Path "$LocalTemplatePath\$Provider"))
    { 
        "Creating Provider $LocalTemplatePath\$Provider"
        New-Item -Path "$LocalTemplatePath" -Name "$Provider" -ItemType container -Force | Out-Null
    }


    #################################
    ## SUBFOLDER DIRECTORY CLEANUP ##
    #################################

    # Create an array of the subfolders found for this provider in the remote template directory
    [array]$RemoteSubfolders = (Get-ChildItem "$RemoteTemplatePath\$Provider" -Exclude "XML" -Directory -ErrorAction Stop).Name

    # Check Local subfolder to see if something is present that is not present in the remote location, and remove it (cleanup)
    [array]$LocalSubfolders = (Get-ChildItem "$LocalTemplatePath\$Provider" -Exclude "XML" -Directory -ErrorAction Stop).Name
    If ($LocalSubfolders)
    {
        $LocalSubfolders | foreach {
        
            $Subfolder = $_

            If ($RemoteSubfolders -notcontains $Subfolder)
            {
                "Removing subfolder $LocalTemplatePath\$Provider\$Subfolder recursively"
                Remove-Item -Path "$LocalTemplatePath\$Provider\$Subfolder" -Recurse -Force
            }

        }
    }


    ##################################
    ## SUBFOLDER DIRECTORY CREATION ##
    ##################################

    # For each remote subfolder...
    $RemoteSubfolders | foreach {
        
        $Subfolder = $_

        # Create the subfolder directory if required
        If (!(Test-Path -Path "$LocalTemplatePath\$Provider\$Subfolder"))
        { 
            "Creating subfolder $LocalTemplatePath\$Provider\$Subfolder"
            New-Item -Path "$LocalTemplatePath\$Provider" -Name "$Subfolder" -ItemType container -Force | Out-Null
        }

    }



    ##############################
    ## TEMPLATE FILE ACTIVITIES ##
    ##############################

    $RemoteSubfolders | foreach {
        
        $Subfolder = $_

        # Create an array of template filenames present in the REMOTE path
        [array]$RemoteFileArray = (Get-ChildItem "$RemoteTemplatePath\$Provider\$Subfolder" -File).Name 

        # Create an array of template filenames present in the LOCAL path
        [array]$LocalFileArray = (Get-ChildItem "$LocalTemplatePath\$Provider\$Subfolder" -File).Name 


        ###########################
        ## TEMPLATE FILE CLEANUP ##
        ###########################

        # Check each local file to see if it is present remotely (cleanup)
        If ($LocalFileArray)
        {
            $LocalFileArray | foreach {

                $LocalFile = $_
                If ($RemoteFileArray -notcontains $LocalFile)
                {
                    "Removing file $LocalTemplatePath\$Provider\$Subfolder\$LocalFile"
                    Remove-Item -Path "$LocalTemplatePath\$Provider\$Subfolder\$LocalFile" -Force
                }

            }
        }

        # Loop through each file in the remote template path
        $RemoteFileArray | foreach {
            
            ############################
            ## TEMPLATE FILE CREATION ##
            ############################
            
            # Copy the remote template file locally if required
            $File = $_
            If ($LocalFileArray -notcontains $File)
            { 
                "Copying file $RemoteTemplatePath\$Provider\$Subfolder\$File to $LocalTemplatePath\$Provider\$Subfolder because it doesn't exist"
                Copy-Item -Path "$RemoteTemplatePath\$Provider\$Subfolder\$File" -Destination "$LocalTemplatePath\$Provider\$Subfolder" -Force
            }

            ############################################
            ## TEMPLATE UPDATE BASED ON HASH MISMATCH ##
            ############################################

            # Check Hash, copy over if mismatch
            $RemoteFileHash = (Get-FileHash -Path "$RemoteTemplatePath\$Provider\$Subfolder\$File").Hash
            $LocalFileHash = (Get-FileHash -Path "$LocalTemplatePath\$Provider\$Subfolder\$File").Hash
            If ($LocalFileHash)
            {
                If ($RemoteFileHash -ne $LocalFileHash)
                {
                    "Copying file $RemoteTemplatePath\$Provider\$Subfolder\$File to $LocalTemplatePath\$Provider\$Subfolder because the hash doesn't match"
                    Copy-Item -Path "$RemoteTemplatePath\$Provider\$Subfolder\$File" -Destination "$LocalTemplatePath\$Provider\$Subfolder" -Force
                }
            }

        }

    }

}
