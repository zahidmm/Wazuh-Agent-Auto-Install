# Variables
$ManagerIP = "192.168.51.1"    # <<< CHANGE IT <<<
$RegistrationIP = "192.168.51.1"    # <<< CHANGE IT <<<
$AgentGroup = "default"
$SysmonConfigURL = "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml"
$WazuhAgentDownloadURL = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.7.5-1.msi"
$AuditLogPath = "$env:TMP\audit-config-log.txt"

# Temporary Paths
$TempPath = "$env:TMP"
$WazuhAgentPath = "$TempPath\wazuh-agent.msi"
$SysmonZipPath = "$TempPath\Sysmon.zip"
$SysmonPath = "$TempPath\Sysmon64.exe"
$SysmonConfigPath = "$TempPath\sysmonconfig.xml"
$LogPath = "$TempPath\install-log.txt"

# Log Initialization
Write-Host "Starting installation..." | Out-File $LogPath -Append

# Wazuh Agent Installation
try {
    Write-Host "Downloading Wazuh agent..."
    Invoke-WebRequest -Uri $WazuhAgentDownloadURL -OutFile $WazuhAgentPath
    if (-Not (Test-Path $WazuhAgentPath)) {
        throw "Wazuh agent download failed."
    }
    Write-Host "Installing Wazuh agent..."
    Start-Process msiexec.exe -ArgumentList "/i $WazuhAgentPath /q WAZUH_MANAGER=$ManagerIP WAZUH_REGISTRATION_SERVER=$RegistrationIP WAZUH_AGENT_GROUP=$AgentGroup" -Wait
} catch {
    Write-Error "Failed to install Wazuh agent. Error: $_" | Out-File $LogPath -Append
    exit 1
}

# Restart Wazuh Agent Service
try {
    Write-Host "Restarting Wazuh agent service..."
    Start-Process -NoNewWindow -FilePath "cmd.exe" -ArgumentList "/c NET START WazuhSvc" -Wait
} catch {
    Write-Error "Failed to restart Wazuh agent service. Error: $_" | Out-File $LogPath -Append
    exit 1
}

# Sysmon Installation
try {
    Write-Host "Downloading Sysmon..."
    Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile $SysmonZipPath
    if (-Not (Test-Path $SysmonZipPath)) {
        throw "Sysmon download failed."
    }
    Write-Host "Extracting Sysmon..."
    Expand-Archive -Path $SysmonZipPath -DestinationPath $TempPath -Force

    Write-Host "Downloading Sysmon configuration..."
    Invoke-WebRequest -Uri $SysmonConfigURL -OutFile $SysmonConfigPath
    if (-Not (Test-Path $SysmonConfigPath)) {
        throw "Sysmon configuration download failed."
    }

    Write-Host "Installing Sysmon with configuration..."
    Start-Process "$SysmonPath" -ArgumentList "-accepteula -i $SysmonConfigPath" -Wait
} catch {
    Write-Error "Sysmon installation failed. Error: $_" | Out-File $LogPath -Append
    exit 1
}

# Cleanup
try {
    Write-Host "Cleaning up temporary files..."
    Remove-Item $WazuhAgentPath -Force -ErrorAction SilentlyContinue
    Remove-Item $SysmonZipPath -Force -ErrorAction SilentlyContinue
    Remove-Item $SysmonPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Error "Cleanup failed. Error: $_" | Out-File $LogPath -Append
}

# Log Initialization
Write-Host "Starting Audit Process Creation configuration..." | Out-File $AuditLogPath -Append

try {
    # Enable Process Creation Auditing
    Write-Host "Enabling Audit Process Creation..."
    AuditPol /set /subcategory:"Process Creation" /success:enable /failure:enable | Out-File $AuditLogPath -Append
    
    # Verify the configuration
    Write-Host "Verifying Audit Process Creation configuration..."
    $AuditStatus = AuditPol /get /subcategory:"Process Creation"
    Write-Host $AuditStatus | Out-File $AuditLogPath -Append
    Write-Host "Audit Process Creation successfully enabled!"
} catch {
    Write-Error "Failed to enable Audit Process Creation. Error: $_" | Out-File $AuditLogPath -Append
    exit 1
}

# Enable Command Line Process Logging
Write-Host "Enabling command line logging for process creation..."
try {
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" -Name "ProcessCreationIncludeCmdLine_Enabled" -Value 1 -PropertyType DWord -Force | Out-File $AuditLogPath -Append
    Write-Host "Command line logging successfully enabled!"
} catch {
    Write-Error "Failed to enable command line logging. Error: $_" | Out-File $AuditLogPath -Append
    exit 1
}

Write-Host "Audit Process Creation configuration completed successfully!" | Out-File $AuditLogPath -Append

Write-Host "Installation complete!" | Out-File $LogPath -Append
