
#region Initialization
# Add the VMware Module
Import-Module VMware.PowerCLI

# Get Admin Credentials
$Credentials = Get-Credential

# Connect to vCenter
Connect-VIServer -Server <your vcenter here> -Credential $Credentials

# Existing DNS Server to check for before updating
$ExistingDNSServer = <your old DNS server here>

# New DNS Servers to set on each server
$NewPrimaryDNSServer = <your new primary DNS server here>
$NewSecondaryDNSServer = <your new secondary DNS server here>

# The VMware Cluster containing the servers on which we want to update the DNS server settings
$VMCluster = <your VMware cluster here>
#endregion Initialization

# Don't edit below here...

function Get-NicName {
    param (
        [Parameter(Mandatory=$true)][String]$ComputerName
    )
    Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -Credential $Credentials | Where-Object {$_.DNSServerSearchOrder -contains $ExistingDNSServer} | ForEach-Object {
        $filter = "Index = $($_.Index)"
        $NicName = (Get-WmiObject Win32_NetworkAdapter -filter $filter -ComputerName $ComputerName -Credential $Credentials).NetConnectionID
        return $NicName
    }
}

function Set-DnsServerIpAddresses {
    param (
        [Parameter(Mandatory=$true)][String]$ComputerName,
        [Parameter(Mandatory=$true)][String]$NicName,
        [Parameter(Mandatory=$true)][String]$PrimaryDNS,
        [Parameter(Mandatory=$true)][String]$SecondaryDNS
    )
    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet) {
        Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ScriptBlock { param ($ComputerName, $NicName, $PrimaryDNS, $SecondaryDNS)
            Write-Host "Clearing DNS Server settings on $NicNAme for $ComputerName"
            Invoke-Expression "netsh interface ip delete dnsservers ""$NicName"" all"
            Write-Host "Setting $PrimaryDNS as the Primary DNS server on $NicName for $ComputerName"
            Invoke-Expression "netsh interface ip add dns name=""$NicName"" addr=$PrimaryDNS"
            Write-Host "Setting $SecondaryDNS as the Secondary DNS server on $NicName for $ComputerName"
            Invoke-Expression "netsh interface ip add dns name=""$NicName"" addr=$SecondaryDNS index=2"
        } -ArgumentList $ComputerName, $NicName, $PrimaryDNS, $SecondaryDNS
    } else {
        Write-Host "Can't access $ComputerName. This computer is not online."
    }
}

$vmlist = Get-Cluster $VMCluster | Get-VM | Where-Object {$_.Guest -like "*Windows*"} | Sort-Object name

<# Running the code

$vmlist | ForEach-Object {
    $adapter = Get-NicName -ComputerName $_.Name
    #Write-Host $adapter
    Set-DnsServerIpAddresses -ComputerName $_.Name -NicName $adapter -PrimaryDNS $NewPrimaryDNSServer -SecondaryDNS $NewSecondaryDNSServer
}
#>

<# Clean up
Disconnect-VIServer -Force -Confirm:$false
Remove-Module VMware.PowerCLI
#>