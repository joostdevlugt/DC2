Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
Install-ADDSForest -DomainName "adatum.com" -DomainNetBiosName "ADATUM" -InstallDns:$true -NoRebootOnCompletion:$true