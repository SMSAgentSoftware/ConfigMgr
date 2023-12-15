<#

.SYNOPSIS
    Gets the total content sizes of packages in the ConfigMgr Software Library, with the option to target a specific console folder.

.DESCRIPTION
    This script will get the total size of all the packages of the type you specify in the ConfigMgr Software Library.  You can do this for Applications,
    Standard Packages, Software Update Packages, Driver Packages, OS Image Packages and Boot Image Packages.
    In the case of Applications, Standard Packages and Driver Packages, you can limit your results to a specific console folder, if you organise those
    package types using folders.
    Using the -verbose switch will also report the sizes of the individual packages in the script window.

.PARAMETER Applications
    Specify this switch to search Application content

.PARAMETER Packages
    Specify this switch to search Standard Package content

.PARAMETER DriverPackages
    Specify this switch to search DriverPackage content

.PARAMETER SoftwareUpdatePackages
    Specify this switch to search SoftwareUpdatePackage content

.PARAMETER OSImages
    Specify this switch to search OSImage content

.PARAMETER BootImages
    Specify this switch to search BootImage content

.PARAMETER FolderName
    For Applications, Packages and DriverPackages, use this optional parameter to specify the name of a console folder containing your packages

.PARAMETER SiteServer
    The Site Server name.  If not specified, the parameter default will be used.

.PARAMETER SiteCode
    The Site Code.  If not specified, the parameter default will be used.


.EXAMPLE
    .\Get-CMSelectedSoftwareContentSizes.ps1 -Applications
    This will calculate the total content size for all Applications in the Application node in the ConfigMgr console, including each deployment type for each Application.

.EXAMPLE
    .\Get-CMSelectedSoftwareContentSizes.ps1 -Applications -FolderName "Default Apps"
    This will calculate the total content size of all Applications in the 'Default Apps' console folder, in the Applications node.

.EXAMPLE
    .\Get-CMSelectedSoftwareContentSizes.ps1 -Packages -FolderName "Driver Applications" -Verbose
    This will calculate the total content size of all standard packages in the 'Driver Applications' console folder, in the Packages node, and return verbose
    output including the content size for each individual package.

.EXAMPLE
    .\Get-CMSelectedSoftwareContentSizes.ps1 -OSImages -Verbose
    This will calculate the total content size of all Operating System Images in the Operating System Images node in the ConfigMgr console, and return verbose
    output including the content size of each individual OS image.

.EXAMPLE
    .\Get-CMSelectedSoftwareContentSizes.ps1 -DriverPackages -SiteServer sccmsrv-01 -SiteCode ABC -Verbose
    This will calculate the total content size of all Driver Packages in the Driver Packages node in the ConfigMgr console, and return verbose
    output including the content size of each individual OS image.  The site server and site code are different to the default and have been specified.

.NOTES
    Script name: Get-CMSelectedSoftwareContentSizes.ps1
    Author:      Trevor Jones
    Contact:     @trevor_smsagent
    DateCreated: 2015-04-17
    Link:        http://smsagent.wordpress.com

#>

[CmdletBinding(SupportsShouldProcess=$True)]
    param
        (
        [Parameter(ParameterSetName="Applications",Mandatory=$True)]
            [switch]$Applications,
        [Parameter(ParameterSetName="Packages",Mandatory=$True)]
            [switch]$Packages,          
         [Parameter(ParameterSetName="DriverPackages",Mandatory=$True)]
            [switch]$DriverPackages,         
        [Parameter(ParameterSetName="SoftwareUpdatePackages",Mandatory=$True)]
            [switch]$SoftwareUpdatePackages,          
         [Parameter(ParameterSetName="OSImages",Mandatory=$True)]
            [switch]$OSImages,         
        [Parameter(ParameterSetName="BootImages",Mandatory=$True)]
            [switch]$BootImages,
                      
        [Parameter(ParameterSetName="Applications",Mandatory=$False,HelpMessage="The name of the console folder containing the applications")]
        [Parameter(ParameterSetName="Packages",Mandatory=$False,HelpMessage="The name of the console folder containing the packages")]
        [Parameter(ParameterSetName="DriverPackages",Mandatory=$False,HelpMessage="The name of the console folder containing the driver packages")]
            [ValidateNotNullOrEmpty()]
                [string]$FolderName="",
        
        [Parameter(
            Mandatory=$False,
            HelpMessage="The Site Server name"
            )]
            [string]$SiteServer="mysccmserver",
        
        [Parameter(
            Mandatory=$False,
            HelpMessage="The Site Code"
            )]
            [string]$SiteCode="ABC"
        )

$ErrorActionPreference = "Stop"


switch ($PSCmdlet.ParameterSetName) {

################
# Applications #
################

"Applications" {

if ($FolderName -ne "")
    {
        # Get FolderID
        Write-Verbose "Getting FolderID of Console Folder '$FolderName'"
        $FolderID = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" `
        -Query "select * from SMS_ObjectContainerNode where Name='$FolderName' and ObjectType=6000" | Select ContainerNodeID
        $FolderID = $FolderID.ContainerNodeID
        If ($FolderID -eq $null -or $FolderID -eq "")
            {write-host "No folderID found.  Check the folder name is correct." -ForegroundColor Red; break}
        Write-Verbose "  $FolderID"
        
        # Get InstanceKey of Folder Members
        Write-Verbose "Getting Members of Folder"
        $FolderMembers = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" `
        -Query "select * from SMS_ObjectContainerItem where ContainerNodeID='$FolderID'" | Select * | Select InstanceKey
        $FolderMembers = $FolderMembers.InstanceKey
        write-Verbose "  Found $($FolderMembers.Count) applications"
        
        # Get Application name of each Folder member
        write-Verbose "Getting Applications"
        $totalsize = 0
        foreach ($foldermember in $foldermembers)
            {
                $PKG = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_ContentPackage where SecurityKey='$Foldermember'" | Select Name,PackageSize
                write-Verbose "  $($PKG.Name)`: $(($($PKG.PackageSize) / 1KB).ToString(".00")) MB"
                $totalsize = $totalsize + $PKG.PackageSize
            }
        
        write-host "Total size of all content files for every application in the '$FolderName' folder is:" -ForegroundColor Green
        if ($totalsize -le 1000)
            {
                write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
            }
        elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
            {
                write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
            }
        else
            {
                write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
            }
    }


if ($FolderName -eq "")
    {
        # Get Applications
        write-Verbose "Getting Applications"
        $PKGs = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_ContentPackage" | Sort Name | Select Name,PackageSize | Out-GridView -Title "Select Applications" -OutputMode Multiple
        write-Verbose "Selected $($PKGs.Count) Applications"
        
        # Get content sizes
        $totalsize = 0
        foreach ($PKG in $PKGs)
            {
                write-Verbose "  $($PKG.Name)`: $(($($PKG.PackageSize) / 1KB).ToString(".00")) MB"
                $totalsize = $totalsize + $PKG.PackageSize
            }
        
        write-host "Total size of all content files for all selected applications is:" -ForegroundColor Green
        if ($totalsize -le 1000)
            {
                write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
            }
        elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
            {
                write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
            }
        else
            {
                write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
            }
    }
}



############
# Packages #
############

"Packages" {

if ($FolderName -ne "")
    {
        # Get FolderID
        Write-Verbose "Getting FolderID of Console Folder '$FolderName'"
        $FolderID = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" `
        -Query "select * from SMS_ObjectContainerNode where Name='$FolderName' and ObjectType=2" | Select ContainerNodeID
        $FolderID = $FolderID.ContainerNodeID
        If ($FolderID -eq $null -or $FolderID -eq "")
            {write-host "No folderID found.  Check the folder name is correct." -ForegroundColor Red; break}
        Write-Verbose "  $FolderID"
        
        # Get InstanceKey of Folder Members
        Write-Verbose "Getting Members of Folder"
        $FolderMembers = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" `
        -Query "select * from SMS_ObjectContainerItem where ContainerNodeID='$FolderID'" | Select * | Select InstanceKey
        $FolderMembers = $FolderMembers.InstanceKey
        write-Verbose "  Found $($FolderMembers.Count) packages"
        
        # Get Package name of each Folder member
        write-Verbose "Getting Packages"
        $totalsize = 0
        foreach ($foldermember in $foldermembers)
            {
                $PKG = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_Package where PackageID='$Foldermember'" | Select Name,PackageSize
                write-Verbose "  $($PKG.Name)`: $(($($PKG.PackageSize) / 1KB).ToString(".00")) MB"
                $totalsize = $totalsize + $PKG.PackageSize
            }
        
        write-host "Total Size of all content files for every package in the '$FolderName' folder is:" -ForegroundColor Green
        if ($totalsize -le 1000)
            {
                write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
            }
        elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
            {
                write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
            }
        else
            {
                write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
            }
    }
        
        
if ($FolderName -eq "")
    {
        # Get Packages
        write-Verbose "Getting Packages"
        $PKGs = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_Package" | Sort Name | Select Name,PackageSize | Out-GridView -Title "Select Packages" -OutputMode Multiple
        write-Verbose "Selected $($PKGs.Count) Packages"
        
        # Get content sizes
        $totalsize = 0
        foreach ($PKG in $PKGs)
            {
                write-Verbose "  $($PKG.Name)`: $(($($PKG.PackageSize) / 1KB).ToString(".00")) MB"
                $totalsize = $totalsize + $PKG.PackageSize
            }
        
        write-host "Total Size of all content files for all selected standard packages is:" -ForegroundColor Green
        if ($totalsize -le 1000)
            {
                write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
            }
        elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
            {
                write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
            }
        else
            {
                write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
            }
    }
}



###################
# Driver Packages #
###################

"DriverPackages" {

# No folder name specified
if ($FolderName -ne "")
    {
        # Get FolderID
        Write-Verbose "Getting FolderID of Console Folder '$FolderName'"
        $FolderID = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" `
        -Query "select * from SMS_ObjectContainerNode where Name='$FolderName' and ObjectType=23" | Select ContainerNodeID
        $FolderID = $FolderID.ContainerNodeID
        If ($FolderID -eq $null -or $FolderID -eq "")
            {write-host "No folderID found.  Check the folder name is correct." -ForegroundColor Red; break}
        Write-Verbose "  $FolderID"
        
        # Get InstanceKey of Folder Members
        Write-Verbose "Getting Members of Folder"
        $FolderMembers = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" `
        -Query "select * from SMS_ObjectContainerItem where ContainerNodeID='$FolderID'" | Select * | Select InstanceKey
        $FolderMembers = $FolderMembers.InstanceKey
        write-Verbose "  Found $($FolderMembers.Count) driver packs"
        
        # Get driver package name of each Folder member
        write-Verbose "Getting Driver Pack Names"
        $totalsize = 0
        foreach ($foldermember in $foldermembers)
            {
                $DriverPack = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_DriverPackage where PackageID='$Foldermember'" | Select Name,PackageSize
                write-Verbose "  $($DriverPack.Name)`: $(($($DriverPack.PackageSize) / 1KB).ToString(".00")) MB"
                $totalsize = $totalsize + $DriverPack.PackageSize
            }
        
        write-host "Total Size of all driver packages in the '$FolderName' folder is:" -ForegroundColor Green
        if ($totalsize -le 1000)
            {
                write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
            }
        elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
            {
                write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
            }
        else
            {
                write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
            }
    }


# Folder name specified
if ($FolderName -eq "")
    {
        # Get driver Package names
        write-Verbose "Getting Driver Packages"
        
        $PKGs = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_DriverPackage" | Sort Name | Select Name,PackageSize | Out-GridView -Title "Select Driver Packages" -OutputMode Multiple
        write-Verbose "Selected $($PKGs.Count) Driver Packages"
        $totalsize = 0
        foreach ($PKG in $PKGs)
            {
                write-Verbose "  $($PKG.Name)`: $(($($PKG.PackageSize) / 1KB).ToString(".00")) MB"
                $totalsize = $totalsize + $PKG.PackageSize
            }
        
        write-host "Total Size of all content files for all selected driver packages is:" -ForegroundColor Green
        if ($totalsize -le 1000)
            {
                write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
            }
        elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
            {
                write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
            }
        else
            {
                write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
            }
    }
}



############################
# Software Update Packages #
############################

"SoftwareUpdatePackages" {

# Get Software Update Packages
$SUPkgs = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_SoftwareUpdatesPackage" | Select Name,PackageSize  | Out-GridView -Title "Select Software Update Packages" -OutputMode Multiple
write-verbose "Selected $($SUPkgs.Count) Software Update Packages"
$totalsize = 0
foreach ($SUPkg in $SUPkgs)
    {
        write-verbose "  $($SUPkg.Name)`: $(($($SUPkg.PackageSize) / 1KB).ToString(".00")) MB"
        $totalsize = $totalsize + $SUPkg.PackageSize
    }
 
write-host "Total Size of all selected Software Update packages is:" -ForegroundColor Green
if ($totalsize -le 1000)
    {
        write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
    }
elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
    {
        write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
    }
else
    {
        write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
    }
}



#############
# OS Images #
#############

"OSImages" {

# Get OS Images
$OSImgs = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_ImagePackage" | Select Name,PackageSize | Out-GridView -Title "Select Operating System Image Packages" -OutputMode Multiple
write-verbose "Selected $($OSImgs.Count) OS Images"
$totalsize = 0
foreach ($OSImg in $OSImgs)
    {
        write-verbose "  $($OSImg.Name)`: $(($($OSImg.PackageSize) / 1KB).ToString(".00")) MB"
        $totalsize = $totalsize + $OSImg.PackageSize
    }
 
write-host "Total Size of all selected OS images is:" -ForegroundColor Green
if ($totalsize -le 1000)
    {
        write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
    }
elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
    {
        write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
    }
else
    {
        write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
    }
}



###############
# Boot Images #
###############

"BootImages" {

# Get Boot Images
$BootImgs = Get-WmiObject -Namespace "ROOT\SMS\Site_$SiteCode" -Query "select * from SMS_BootImagePackage" | Select Name,PackageSize | Out-GridView -Title "Select Boot Image Packages" -OutputMode Multiple
write-verbose "Selected $($BootImgs.Count) Boot Images"
$totalsize = 0
foreach ($BootImg in $BootImgs)
    {
        write-verbose "  $($BootImg.Name)`: $(($($BootImg.PackageSize) / 1KB).ToString(".00")) MB"
        $totalsize = $totalsize + $BootImg.PackageSize
    }
 
write-host "Total Size of all selected boot images is:" -ForegroundColor Green
if ($totalsize -le 1000)
    {
        write-host "$(($totalsize).ToString(".00")) KB" -ForegroundColor Green
    }
elseif ($totalsize -gt 1000 -and $totalsize -le 1000000)
    {
        write-host "$(($totalsize / 1KB).ToString(".00")) MB" -ForegroundColor Green
    }
else
    {
        write-host "$(($totalsize / 1MB).ToString(".00")) GB" -ForegroundColor Green
    }
}
}