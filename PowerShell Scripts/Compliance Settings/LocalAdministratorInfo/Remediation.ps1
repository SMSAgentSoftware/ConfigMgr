

Function New-RegistryItem {

    # Adds data to the registry in HKLM:\Software\IT_Local

    [cmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$ValueName,

        [Parameter(Mandatory=$true)]
        [string]$Value       
    )

    $registryPath = "HKLM:SOFTWARE\IT_Local\LocalAdminInfo"

    ## Creating the registry node
    if (!(test-path $registryPath))
    {
           
        try
        {
            New-Item -Path $registryPath -force -ErrorAction stop | Out-Null
        }
        catch
        { }
    }

    ## Creating the registry string and setting its value
    try
    {
        New-ItemProperty -Path $registryPath -Name $ValueName -PropertyType STRING -Value $Value -Force -ErrorAction Stop | Out-Null
    }
    catch
    { }
}

Function Get-NestedGroupMembership {
   
    # Gets nested group membership for a user from a group principal up to 3 levels (ie groups within a group)

    Param(
        [Parameter(Mandatory=$true)]
        [object]$GroupPrincipal,

        [Parameter(Mandatory=$true)]
        [string]$TopConsoleUser,

        [Parameter(Mandatory=$false)]
        [ValidateSet(1,2,3)] 
        [int]$Levels = 3     
    )

    # Create an array to contain the results
    $NestedGroupMembership = @()

    # Get Local Admin Group members that are groups
    $Level1Groups = @()
    $GroupPrincipal.Members | Foreach {
        If ($_.IsSecurityGroup)
        {
            $Level1Groups += $_
        }
    }

    ## LEVEL 1 ##
    If ($Level1Groups)
    {
        # If the nested group contains the user name
        $Level1Groups | foreach {
            If ($_.Members.SamAccountName -contains $TopConsoleUser)
            {
                $NestedGroupMembership += $_.SamAccountName
            }
        }

        ## LEVEL 2##
        # If the nested group contains other nested groups
        if ($Levels -ge 2)
        {
            $Level2Groups = @()
            $Level1Groups | foreach {
                $Members = $_.Members
                $Members | foreach {
                    If ($_.IsSecurityGroup)
                    {
                        $Level2Groups += $_
                    }
                }

                # If the nested group contains the user name
                If ($Level2Groups)
                {
                    $Level2Groups | Foreach {
                        If ($_.Members.SamAccountName -contains $TopConsoleUser)
                        {
                            $NestedGroupMembership += $_.SamAccountName
                        }
                    }
                }

                ## LEVEL 3 ##
                # If the nested group contains other nested groups
                if ($Levels -ge 3)
                {
                    $Level3Groups = @()
                    $Level2Groups | foreach {
                        $Members = $_.Members
                        $Members | foreach {
                            If ($_.IsSecurityGroup)
                            {
                                $Level3Groups += $_
                            }
                        }

                        # If the nested group contains the user name
                        If ($Level3Groups)
                        {
                            $Level3Groups | Foreach {
                                If ($_.Members.SamAccountName -contains $TopConsoleUser)
                                {
                                    $NestedGroupMembership += $_.SamAccountName
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Return $NestedGroupMembership
}

# Define the list of properties we want
$Properties = @(
    "ComputerName",
    "TopConsoleUser",
    "TopConsoleUserIsAdmin",
    "AdminGroupMembershipType",
    "LocalAdminGroupMembership",
    "NestedGroupMembership",
    "OSInstallDate",
    "OSAgeInDays",
    "LastUpdated"
)

# Create a datatable to hold the data
$Datatable = New-Object System.Data.DataTable
$Datatable.Columns.AddRange($Properties)

# Find top console user
Try
{
    $TopConsoleUser = Get-WmiObject -Namespace ROOT\cimv2\sms -Class SMS_SystemConsoleUsage -Property TopConsoleUser -ErrorAction Stop | Select -ExpandProperty TopConsoleUser
    # Or optionally use the primary user via UDA, but this can contain multiple user entries...
    #$TopConsoleUser = Get-WmiObject -Namespace ROOT\CCM\Policy\Machine\ActualConfig -Class CCM_UserAffinity -Property ConsoleUser -ErrorAction Stop | Select -ExpandProperty ConsoleUser
}
Catch
{
    $TopConsoleUser = "Unknown"
}

# If domain account, strip the domain
if ($TopConsoleUser -match "\\")
{
    $TopConsoleUser = $TopConsoleUser.Split('\')[1]
}

# Create windows identity object for the user account
If ($TopConsoleUser -ne "Unknown")
{
    Try
    {
        $ID = New-Object Security.Principal.WindowsIdentity -ArgumentList $TopConsoleUser

        # Check if the user has the local admin claim 
        $IsLocalAdmin = $ID.HasClaim('http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid','S-1-5-32-544')
        $ID.Dispose()
    }
    Catch
    {
        $IsLocalAdmin = "Unknown"
    }
}
Else
{
    $IsLocalAdmin = "Unknown"
}

# Get the full local admin group membership
Try
{
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
    $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
    $PrincipalContext = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ContextType, $($env:COMPUTERNAME) -ErrorAction Stop
    $IdentityType = [System.DirectoryServices.AccountManagement.IdentityType]::Name
    $GroupPrincipal = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($PrincipalContext, $IdentityType, “Administrators”)
    $LocalAdminMembers = $GroupPrincipal.Members | select -ExpandProperty SamAccountName | Sort-Object
}
Catch 
{
    $LocalAdminMembers = "Unknown"
}

# Check the membership of any nested groups in the local admin group (up to 3 levels)
If ($IsLocalAdmin -eq $True -and $LocalAdminMembers -ne "Unknown")
{
    [array]$NestedGroupMembership = Get-NestedGroupMembership -GroupPrincipal $GroupPrincipal -TopConsoleUser $TopConsoleUser -Levels 3
    $PrincipalContext.Dispose()
    $GroupPrincipal.Dispose()
}
ElseIf ($IsLocalAdmin -eq $False)
{
    $NestedGroupMembership = "N/A"
}
Else
{
    $NestedGroupMembership = "Unknown"
}

# Convert local admin membership to string format
If ($LocalAdminMembers -ne "Unknown")
{
    $LocalAdminMembers | Foreach {
        If ($LocalAdminMembersString)
        {
            $LocalAdminMembersString = $LocalAdminMembersString + ", $_"
        }
        Else
        {
            $LocalAdminMembersString = $_       
        }
    }
}
Else
{
    $LocalAdminMembersString = "Unknown" 
}

# Determine if user is local admin by direct membership, nested group or both
If ($IsLocalAdmin -eq $true)
{
    If ($LocalAdminMembers -ne "Unknown")
    {
        If ($LocalAdminMembers -contains $TopConsoleUser -and $NestedGroupMembership.Count -lt 1)
        {
            $AdminGroupMembershipType = "Direct"
        }
        ElseIf ($LocalAdminMembers -notcontains $TopConsoleUser -and $NestedGroupMembership.Count -ge 1)
        {
            $AdminGroupMembershipType = "Nested Group"
        }
        ElseIf ($LocalAdminMembers -contains $TopConsoleUser -and $NestedGroupMembership.Count -ge 1)
        {
            $AdminGroupMembershipType = "Direct and Nested Group"
        }
        Else
        {
            $AdminGroupMembershipType = "Unknown"
        }
    }
    Else
    {
        $AdminGroupMembershipType = "Unknown"
    }
}
Else
{
    $AdminGroupMembershipType = "N/A"
}

# Convert nested group membership to string format
If ($NestedGroupMembership -ne "Unknown" -and $NestedGroupMembership -ne "N/A" -and $AdminGroupMembershipType -ne "Direct")
{
    $NestedGroupMembership | Foreach {
        If ($NestedGroupMembershipString)
        {
            $NestedGroupMembershipString = $NestedGroupMembershipString + ", $_"
        }
        Else
        {
            $NestedGroupMembershipString = $_       
        }
    }
}
ElseIf ($AdminGroupMembershipType -eq "Direct" -or $NestedGroupMembership -eq "N/A")
{
    $NestedGroupMembershipString = "N/A" 
}
Else
{
    $NestedGroupMembershipString = "Unknown" 
}


# Get the Operating System Install Date
Try
{
    [datetime]$InstallDate = [System.Management.ManagementDateTimeConverter]::ToDateTime($(Get-WmiObject win32_OperatingSystem -Property InstallDate -ErrorAction Stop | Select -ExpandProperty InstallDate)) | 
        Get-date -Format 'yyyy-MM-dd HH:mm:ss'
}
Catch
{
    $InstallDate = "Unknown"
}

# Populate the datatable
[void]$Datatable.Rows.Add($env:COMPUTERNAME,$TopConsoleUser,$IsLocalAdmin,$AdminGroupMembershipType,$LocalAdminMembersString,$NestedGroupMembershipString,$($InstallDate | Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$((Get-Date)-($InstallDate)).Days,$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

# Tattoo the registry
If ($Datatable.Rows.Count -eq 1)
{
    $Properties | Foreach {
        Try
        {
            New-RegistryItem -ValueName $_ -Value $Datatable.Rows[0].$_
        }
        Catch {}
    }
}
