

Invoke-VMScript -VM $VMList -GuestCredential $DomainAdmin -ScriptType Powershell -ScriptText 'Get-DnsClientServerAddress|where AddressFamily -eq 2|where {$_.serveraddresses -Contains "172.16.1.2" -or $_.ServerAddresses -Contains "172.16.1.4"}|Set-DnsClientServerAddress -ServerAddresses ("172.16.1.181","172.16.1.182","172.16.1.2","172.16.1.4")' -ErrorAction Ignore
