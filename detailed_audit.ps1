# Variables
$LogPath = "$env:TMP\audit-config-log.txt"

# Log Initialization
Write-Host "Starting Audit Process Creation configuration..." | Out-File $LogPath -Append

try {
    # Enable Process Creation Auditing
    Write-Host "Enabling Audit Process Creation..."
    AuditPol /set /subcategory:"Process Creation" /success:enable /failure:enable | Out-File $LogPath -Append
    
    # Verify the configuration
    Write-Host "Verifying Audit Process Creation configuration..."
    $AuditStatus = AuditPol /get /subcategory:"Process Creation"
    Write-Host $AuditStatus | Out-File $LogPath -Append
    Write-Host "Audit Process Creation successfully enabled!"
} catch {
    Write-Error "Failed to enable Audit Process Creation. Error: $_" | Out-File $LogPath -Append
    exit 1
}

# Enable Command Line Process Logging
Write-Host "Enabling command line logging for process creation..."
try {
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -PropertyType DWord -Force | Out-File $LogPath -Append
    Write-Host "Command line logging successfully enabled!"
} catch {
    Write-Error "Failed to enable command line logging. Error: $_" | Out-File $LogPath -Append
    exit 1
}

Write-Host "Audit Process Creation configuration completed successfully!" | Out-File $LogPath -Append
