# Arguments.
param 
(
	[Microsoft.WindowsAzure.Management.ServiceManagement.Model.PersistentVMRoleContext]$vm = $(throw "'vm' is required."), 
	[string]$csvFile = $(throw "'csvFile' is required."),
	[string]$parameterSet = $(throw "'parameterSet' is required.")
)
Get-ChildItem "${Env:ProgramFiles(x86)}\Microsoft SDKs\Windows Azure\PowerShell\Azure\*.dll" | ForEach-Object {[Reflection.Assembly]::LoadFile($_) | out-null }

# Add endpoints without loadbalancer.
if ($parameterSet -eq "NoLB")
{
    Write-Host -Fore Green "Adding NoLB endpoints:"
    $endpoints = Import-Csv $csvFile -header Name,Protocol,PublicPort,LocalPort -delimiter ';' | foreach {
		New-Object PSObject -prop @{
			Name = $_.Name;
			Protocol = $_.Protocol;
			PublicPort = [int32]$_.PublicPort;
			LocalPort = [int32]$_.LocalPort;
		}
    }

    # Add each endpoint.
    Foreach ($endpoint in $endpoints)
    {
	Add-AzureEndpoint -VM $vm -Name $endpoint.Name -Protocol $endpoint.Protocol.ToLower() -PublicPort $endpoint.PublicPort -LocalPort $endpoint.LocalPort
    }
}
# Add endpoints with loadbalancer.
elseif ($parameterSet -eq "LoadBalanced")
{
    Write-Host -Fore Green "Adding LoadBalanced endpoints:"
    $endpoints = Import-Csv $csvFile -header Name,Protocol,PublicPort,LocalPort,LBSetName,ProbePort,ProbeProtocol,ProbePath -delimiter ';' | foreach {
		New-Object PSObject -prop @{
			Name = $_.Name;
			Protocol = $_.Protocol;
			PublicPort = [int32]$_.PublicPort;
			LocalPort = [int32]$_.LocalPort;
			LBSetName = $_.LBSetName;
			ProbePort = [int32]$_.ProbePort;
			ProbeProtocol = $_.ProbeProtocol;
			ProbePath = $_.ProbePath;
		}
    }

    # Add each endpoint.
    Foreach ($endpoint in $endpoints)
    {
        Add-AzureEndpoint -VM $vm -Name $endpoint.Name -Protocol $endpoint.Protocol.ToLower() -PublicPort $endpoint.PublicPort -LocalPort $endpoint.LocalPort -LBSetName $endpoint.LBSetName -ProbePort $endpoint.ProbePort -ProbeProtocol $endpoint.ProbeProtocol -ProbePath $endpoint.ProbePath
    }
}
else
{
    $(throw "$parameterSet is not supported. Allowed: NoLB, LoadBalanced")
}

# Update VM.
Write-Host -Fore Green "Updating VM..."
$vm | Update-AzureVM 
Write-Host -Fore Green "Done."