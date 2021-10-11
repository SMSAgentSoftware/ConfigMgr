#########################################################################################################
## Script to create compatibility collections in MEMCM for Windows 11 based on custom inventoried data ##
#########################################################################################################

# Windows 11 Version
$W11Version = "21H2"

# Limiting collection
$LimitingCollection = "All Systems"

# Import ConfigMgr Module
Import-Module $env:SMS_ADMIN_UI_PATH.Replace('i386','ConfigurationManager.psd1')
$SiteCode = (Get-PSDrive -PSProvider CMSITE).Name
Set-Location ("$SiteCode" + ":")

# Collection names and query rules
$Collections = [ordered]@{
    "Windows 11 $W11Version Blocked: BDD" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByBdd = ""1"""
    "Windows 11 $W11Version Blocked: Bios" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByBios = ""1"""
    "Windows 11 $W11Version Blocked: ComputerHardwareId" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByComputerHardwareId = ""1"""
    "Windows 11 $W11Version Blocked: CPU" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByCpu = ""1"""
    "Windows 11 $W11Version Blocked: CPUFms" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByCpuFms = ""1"""
    "Windows 11 $W11Version Blocked: DeviceBlock" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByDeviceBlock = ""1"""
    "Windows 11 $W11Version Blocked: HardDiskController" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByHardDiskController = ""1"""
    "Windows 11 $W11Version Blocked: Memory" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByMemory = ""1"""
    "Windows 11 $W11Version Blocked: Network" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByNetwork = ""1"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Any" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.GatedBlockId != ""None"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Id 35004082" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.GatedBlockId = ""35004082"""
    "Windows 11 $W11Version Blocked: Safeguard Hold Id 35881056" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.GatedBlockId = ""35881056"""
    "Windows 11 $W11Version Blocked: SModeState" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedBySModeState = ""1"""
    "Windows 11 $W11Version Blocked: SystemDriveSize" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedBySystemDriveSize = ""1"""
    "Windows 11 $W11Version Blocked: SystemDriveTooFull" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedBySystemDriveTooFull = ""1"""
    "Windows 11 $W11Version Blocked: TPMversion" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByTpmVersion = ""1"""
    "Windows 11 $W11Version Blocked: UefiSecureBoot" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByUefiSecureBoot = ""1"""
    "Windows 11 $W11Version Blocked: UpgradeableBios" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.BlockedByUpgradableBios = ""1"""
    "Windows 11 $W11Version Capable" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.RedReason = ""None"""
    "Windows 11 $W11Version FailedPrereqs" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceId = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.FailedPrereqs != ""None"""
    "Windows 11 $W11Version Has Red Reason" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.RedReason != ""None"""
    "Windows 11 $W11Version UEX Rating Orange" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.UexRatingOrange > ""0"""
    "Windows 11 $W11Version UEX Rating Red" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.UexRatingRed > ""0"""
    "Windows 11 $W11Version UEX Rating Yellow" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwoCM on SMS_G_System_COTwentyOneHTwoCM.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwoCM.UexRatingYellow > ""0"""
    "Windows 11 $W11Version UEX: Green" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.UpgEx = ""Green"""
    "Windows 11 $W11Version UEX: Orange" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.UpgEx = ""Orange"""
    "Windows 11 $W11Version UEX: Red" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.UpgEx = ""Red"""
    "Windows 11 $W11Version UEX: Yellow" = "select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_COTwentyOneHTwo on SMS_G_System_COTwentyOneHTwo.ResourceID = SMS_R_System.ResourceId where SMS_G_System_COTwentyOneHTwo.UpgEx = ""Yellow"""
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