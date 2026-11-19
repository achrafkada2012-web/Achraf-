<#
  Setup-GamingPC.ps1
  Turns a Windows PC into a remote gaming rig for GTA V + FiveM (no Tailscale).

  Run in PowerShell as Administrator:
    Set-ExecutionPolicy -Scope Process Bypass -Force
    .\Setup-GamingPC.ps1

  Streaming options (pick during the script):
    1) Parsec   -> no port forwarding, no public IP needed (easiest)
    2) Sunshine -> use Moonlight as client; needs port forwarding
    3) Both
#>

#Requires -RunAsAdministrator
$ErrorActionPreference = "Stop"

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# 0. Choices
Write-Host "Streaming software:"
Write-Host "  1) Parsec (recommended, no IP needed)"
Write-Host "  2) Sunshine + Moonlight (needs port forwarding)"
Write-Host "  3) Both"
$choice = Read-Host "Choose 1, 2 or 3"

$useParsec   = $choice -in @("1", "3")
$useSunshine = $choice -in @("2", "3")

# 1. Power settings
Step "Power settings (no sleep, high performance)"
powercfg /setactive SCHEME_MIN | Out-Null
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change monitor-timeout-ac 0
powercfg /change hibernate-timeout-ac 0
powercfg /hibernate off

# 2. Remote Desktop (admin access only)
Step "Enable Remote Desktop"
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue

# 3. Install software with winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. Install 'App Installer' from the Microsoft Store and run again."
}

function Install-App($id) {
    Step "Installing $id"
    winget install --id $id -e --silent --accept-package-agreements --accept-source-agreements
}

Install-App "Valve.Steam"
if ($useParsec)   { Install-App "Parsec.Parsec" }
if ($useSunshine) { Install-App "LizardByte.Sunshine" }

# 4. FiveM client
Step "Downloading FiveM"
$fivemDir = "$env:LOCALAPPDATA\FiveM"
New-Item -ItemType Directory -Force -Path $fivemDir | Out-Null
$fivemExe = "$env:USERPROFILE\Downloads\FiveM.exe"
Invoke-WebRequest -Uri "https://runtime.fivem.net/client/FiveM.exe" -OutFile $fivemExe
Write-Host "FiveM downloaded to $fivemExe (run it after GTA V is installed)."

# 5. Firewall rules for Sunshine (web UI port 47990 is NOT opened)
if ($useSunshine) {
    Step "Firewall rules for Sunshine"
    $tcp = 47984, 47989, 48010
    $udp = 47998, 47999, 48000, 48002, 48010
    New-NetFirewallRule -DisplayName "Sunshine TCP" -Direction Inbound -Protocol TCP `
        -LocalPort $tcp -Action Allow -ErrorAction SilentlyContinue | Out-Null
    New-NetFirewallRule -DisplayName "Sunshine UDP" -Direction Inbound -Protocol UDP `
        -LocalPort $udp -Action Allow -ErrorAction SilentlyContinue | Out-Null
}

# 6. Prevent forced reboot while logged in after Windows Update
Step "Disable auto-reboot while a user is logged in"
$wu = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
New-Item -Path $wu -Force | Out-Null
Set-ItemProperty -Path $wu -Name "NoAutoRebootWithLoggedOnUsers" -Value 1 -Type DWord

# 7. Open Steam page for GTA V
Step "Opening GTA V in Steam (log in and install it)"
Start-Process "steam://install/271590"

Write-Host @"

=========================== DONE ===========================
Manual steps left:

1) Log in to Steam and install GTA V (you must own it), then run FiveM.exe.
2) Parsec: sign in to your account, enable 'Host' mode. Connect from any device.
3) Sunshine: open https://localhost:47990 , set a STRONG username/password,
   then pair from Moonlight using the PC's IP address.
4) Open the Sunshine ports in your cloud provider's firewall / router:
     TCP 47984, 47989, 48010
     UDP 47998, 47999, 48000, 48002, 48010
   Do NOT expose port 47990 (web admin) or 3389 (RDP) to the internet.
5) No monitor attached? Use an HDMI dummy plug (or a virtual display driver),
   otherwise streaming shows a black screen.
6) Optional auto-login: run 'netplwiz' and untick
   'Users must enter a user name and password'.
============================================================
"@ -ForegroundColor Green
