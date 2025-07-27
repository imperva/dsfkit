locals {
  user_data_windows = <<-EOF
    <powershell>
    # Install OpenSSH Server
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

    # Start and configure OpenSSH Server
    Start-Service sshd
    Set-Service -Name sshd -StartupType 'Automatic'

    # Configure firewall to allow SSH
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
      Write-Output "Firewall Rule 'OpenSSH-Server-In-TCP' does not exist, creating it..."
      New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
      Write-Output "Firewall rule 'OpenSSH-Server-In-TCP' has been created and exists."
    }

    # Create .ssh directory for Administrator
    $adminSshDir = "$env:SystemDrive\\Users\\Administrator\\.ssh"
    New-Item -ItemType Directory -Force -Path $adminSshDir

    # Retrieve the SSH public key from instance metadata
    $token = Invoke-RestMethod -Uri "http://169.254.169.254/latest/api/token" -Method PUT  -Headers @{ "X-aws-ec2-metadata-token-ttl-seconds" = "21600" }
    $instanceMetadataUri = "http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key"
    $authorizedKey = Invoke-RestMethod -Uri $instanceMetadataUri -Method Get -Headers @{ "X-aws-ec2-metadata-token" = $token }

    # Add the SSH key to administrators_authorized_keys
    $authorizedKeysPath = "$env:ProgramData\\ssh\\administrators_authorized_keys"
    Add-Content -Force -Path $authorizedKeysPath -Value $authorizedKey
    icacls $authorizedKeysPath /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"

    # Restart SSH service to apply changes
    Restart-Service sshd
    </powershell>
  EOF

  cte_agent_install_command_windows_msi = (
    var.agent_installation.cte_agent_installation_file != null
    ?
    "msiexec.exe /i \"${basename(var.agent_installation.cte_agent_installation_file)}\" /qn /norestart registerhostopts=\"${var.cipher_trust_manager_address} -fam -token=${var.agent_installation.registration_token}\""
    : ""
  )
  cte_agent_install_command_windows_exe = (
    var.agent_installation.cte_agent_installation_file != null
    ?
    "${basename(var.agent_installation.cte_agent_installation_file)} /s /v\" /qn /norestart registerhostopts=\\\"${var.cipher_trust_manager_address} -fam -token=${var.agent_installation.registration_token}\\\"\""
    : ""
  )
  cte_agent_install_command_windows = (
    var.agent_installation.cte_agent_installation_file != null
    ? (
      can(regex(".*\\.exe$", var.agent_installation.cte_agent_installation_file))
      ? local.cte_agent_install_command_windows_exe
      : local.cte_agent_install_command_windows_msi
    )
    : ""
  )

  cte_agent_inline_commands_windows = var.agent_installation.cte_agent_installation_file != null ? [
    local.cte_agent_install_command_windows,
    "if %ERRORLEVEL% EQU 3010 (echo Reboot required, resetting errorlevel && exit /b 0) else (exit /b %ERRORLEVEL%)"
  ] : []
  ddc_agent_inline_commands_windows = var.agent_installation.ddc_agent_installation_file != null ? [
    "msiexec.exe /i \"${basename(var.agent_installation.ddc_agent_installation_file)}\" /qn /norestart TARGETIP=${var.cipher_trust_manager_address}",
    "\"C:\\Program Files (x86)\\Ground Labs\\Enterprise Recon 2\\er2_config_cmd.exe\" -t" # test connection from DDC to CM
  ] : []
  reboot_inline_commands_windows = [
    "echo 'About to reboot the host'",
    "shutdown /r /t 0"
  ]
}

