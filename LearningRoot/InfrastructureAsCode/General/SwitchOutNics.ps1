#$NICs = Get-WMIObject Win32_NetworkAdapterConfiguration | Where-Object {$_.IPEnabled -eq "True"}

<# 

#>
