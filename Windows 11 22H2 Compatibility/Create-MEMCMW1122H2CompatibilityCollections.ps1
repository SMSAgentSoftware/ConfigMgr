##############################################################################################################
## Script to create compatibility collections in MEMCM for Windows 11 22H2 based on custom inventoried data ##
##############################################################################################################

# Windows 11 Version
$W11Version = "22H2"

# Limiting collection
$LimitingCollection = "All Systems"

# Import ConfigMgr Module
Import-Module $env:SMS_ADMIN_UI_PATH.Replace('i386','ConfigurationManager.psd1')
$SiteCode = (Get-PSDrive -PSProvider CMSITE).Name
Set-Location ("$SiteCode" + ":")

# Collection names and query rules
$Collections = [ordered]@{
    "Windows 11 $W11Version Blocked: BDD" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByBdd = ""1"""
    "Windows 11 $W11Version Blocked: Bios" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByBios = ""1"""
    "Windows 11 $W11Version Blocked: ComputerHardwareId" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByComputerHardwareId = ""1"""
    "Windows 11 $W11Version Blocked: CPU" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByCpu = ""1"""
    "Windows 11 $W11Version Blocked: CPUFms" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByCpuFms = ""1"""
    "Windows 11 $W11Version Blocked: DeviceBlock" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByDeviceBlock = ""1"""
    "Windows 11 $W11Version Blocked: HardDiskController" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByHardDiskController = ""1"""
    "Windows 11 $W11Version Blocked: Memory" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByMemory = ""1"""
    "Windows 11 $W11Version Blocked: Network" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByNetwork = ""1"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Any" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.GatedBlockId != ""None"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Id 40667045" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.GatedBlockId = ""40667045"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Id 41291788" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.GatedBlockId = ""41291788"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Id 41332279" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.GatedBlockId = ""41332279"""
    "Windows 11 $W11Version Blocked: SModeState" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedBySModeState = ""1"""
    "Windows 11 $W11Version Blocked: SystemDriveSize" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedBySystemDriveSize = ""1"""
    "Windows 11 $W11Version Blocked: SystemDriveTooFull" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedBySystemDriveTooFull = ""1"""
    "Windows 11 $W11Version Blocked: TPMversion" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByTpmVersion = ""1"""
    "Windows 11 $W11Version Blocked: UefiSecureBoot" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByUefiSecureBoot = ""1"""
    "Windows 11 $W11Version Blocked: UpgradeableBios" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.BlockedByUpgradableBios = ""1"""
    "Windows 11 $W11Version Capable" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceId = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.RedReason = ""None"" and SMS_G_System_NITwentyTwoHTwo.GatedBlockId = ""None"""
    "Windows 11 $W11Version FailedPrereqs" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceId = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.FailedPrereqs != ""None"""
    "Windows 11 $W11Version Has Red Reason" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.RedReason != ""None"""
    "Windows 11 $W11Version UEX Rating Orange" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.UexRatingOrange > ""0"""
    "Windows 11 $W11Version UEX Rating Red" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.UexRatingRed > ""0"""
    "Windows 11 $W11Version UEX Rating Yellow" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwoCM on SMS_G_System_NITwentyTwoHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwoCM.UexRatingYellow > ""0"""
    "Windows 11 $W11Version UEX: Green" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.UpgEx = ""Green"""
    "Windows 11 $W11Version UEX: Orange" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.UpgEx = ""Orange"""
    "Windows 11 $W11Version UEX: Red" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.UpgEx = ""Red"""
    "Windows 11 $W11Version UEX: Yellow" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_NITwentyTwoHTwo on SMS_G_System_NITwentyTwoHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_NITwentyTwoHTwo.UpgEx = ""Yellow"""
}

# Create the collections
foreach ($CollectionName in $Collections.Keys)
{
    Write-host "Creating collection: '$CollectionName'"
    $Query = $Collections["$CollectionName"]
    $Collection = New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $CollectionName -RefreshType Periodic -RefreshSchedule (Convert-CMSchedule -ScheduleString "920A8C0000100008")
    Add-CMDeviceCollectionQueryMembershipRule -CollectionName $Collection.Name -QueryExpression $Query -RuleName "$($Collection.Name)"
}

# Include collection names for the 'Not capable' collection
$IncludeCollections = @(
    "Windows 11 $W11Version Blocked: TPMversion"
    "Windows 11 $W11Version Blocked: BDD"
    "Windows 11 $W11Version Blocked: Bios"
    "Windows 11 $W11Version Blocked: SystemDriveSize"
    "Windows 11 $W11Version Blocked: ComputerHardwareId"
    "Windows 11 $W11Version Blocked: CPU"
    "Windows 11 $W11Version Blocked: CPUFms"
    "Windows 11 $W11Version Blocked: DeviceBlock"
    "Windows 11 $W11Version Blocked: HardDiskController"
    "Windows 11 $W11Version Blocked: Memory"
    "Windows 11 $W11Version Blocked: Network"
    "Windows 11 $W11Version Blocked: SModeState"
    "Windows 11 $W11Version Blocked: SystemDriveTooFull"
    "Windows 11 $W11Version Blocked: UefiSecureBoot"
    "Windows 11 $W11Version Blocked: UpgradeableBios"
    "Windows 11 $W11Version FailedPrereqs"
    "Windows 11 $W11Version Blocked: Safeguard Hold Any"
)
# Create the 'Not capable' collection
$NotCapable = "Windows 11 $W11Version Not Capable"
Write-host "Creating and adding include collections for 'Windows 11 $W11Version Not Capable'"
$Collection = New-CMDeviceCollection -LimitingCollectionName $LimitingCollection -Name $NotCapable -RefreshType Periodic -RefreshSchedule (Convert-CMSchedule -ScheduleString "920A8C0000100008")
foreach ($IncludeCollection in $IncludeCollections)
{
    Add-CMDeviceCollectionIncludeMembershipRule -CollectionName "Windows 11 $W11Version Not Capable" -IncludeCollectionName $IncludeCollection
}
