# Gaming VPS Setup (GTA V + FiveM)

PowerShell script that prepares a **Windows machine with a GPU** for remote gaming.

## Important
GitHub only *stores* this script. It cannot run the game: GitHub Actions runners
have no GPU, are temporary, and gaming/remote-desktop use breaks their terms.
Run the script on a GPU cloud Windows machine (AWS G4dn/G5, Azure NV, Paperspace,
Vast.ai, Shadow PC) or on your own PC.

## Usage
Open PowerShell **as Administrator** on the Windows machine:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Setup-GamingPC.ps1
```

Choose Parsec (easiest) or Sunshine + Moonlight, then install GTA V from Steam
(you must own it) and run FiveM.

## Security
Never expose ports 3389 (RDP) or 47990 (Sunshine admin) to the internet.
