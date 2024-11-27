# Wazuh-Agent-Auto-Install

### Quick Download
Run powershell as Administrator:
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/zahidmm/Wazuh-Agent-Auto-Install/main/win10wazuhagentauto.ps1 -OutFile win10wazuhagentauto.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -File win10wazuhagentauto.ps1
```

### agent.conf
```bash
<localfile>
  <location>Microsoft-Windows-Sysmon/Operational</location>
  <log_format>eventchannel</log_format>
</localfile>
```
