<p align="center"><img src="zombo-watermark.svg" width="300" alt="zombo.exe"></p>

# Windows MAC Spoofer

Simple Windows MAC address changer. Auto-detects your network adapters, then randomizes, sets, or restores the MAC with one script.

> For use on devices and networks you own or are authorized to use.

## Features

- Auto-detects physical network adapters and shows their status and current MAC
- Random MAC, custom MAC, or one-step restore of the original
- Asks for Administrator rights automatically
- Verifies the change and tells you if your driver ignored it

## Requirements

- Windows 10 or 11
- PowerShell 5.1 (built in)
- Administrator rights

## Instructions

### Option 1: Double-click (easiest)

1. Download `MACSpoofer.ps1` and `MACSpoofer.bat` into the **same folder**.
2. Double-click `MACSpoofer.bat`.
3. Click **Yes** on the Administrator prompt.
4. Type the number of the adapter you want to change (the connected one is the default, so you can just press Enter).
5. Choose an option:
   - `1` Random MAC
   - `2` Custom MAC (enter 12 hex digits, e.g. `02-11-22-33-44-55`)
   - `3` Restore the original MAC
6. Wait a few seconds while the adapter restarts. The script prints the new MAC when it's done.

### Option 2: Run the .exe

Download `MACSpoofer.exe` from the [Releases](../../releases) page and double-click it. It asks for Administrator rights itself.

### Option 3: Run from PowerShell

Open PowerShell as Administrator, then:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
cd path\to\the\folder
.\MACSpoofer.ps1
```

## Building the .exe yourself

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
Install-Module ps2exe -Scope CurrentUser
Import-Module ps2exe
Invoke-ps2exe .\MACSpoofer.ps1 .\MACSpoofer.exe -requireAdmin
```

## Verify the change

```powershell
Get-NetAdapter | Select Name, MacAddress
```

or run `ipconfig /all`.

## Restoring your original MAC

Run the tool again and choose option `3`. You can also reboot after removing the setting manually: in Device Manager, open your adapter's **Advanced** tab, select **Network Address**, and choose **Not Present**.

## Notes and limitations

- Your connection drops for a few seconds while the adapter restarts.
- The change is stored in the registry, so it **survives reboots** until you restore it.
- Some drivers (certain Intel and Realtek ones) ignore or reject MAC changes. If the MAC doesn't change, try another adapter or a USB one.
- Some drivers only accept MACs whose second hex digit is `2`, `6`, `A`, or `E`. The random option always uses `02`.
- Antivirus or SmartScreen may flag the .exe because it's an unsigned PowerShell wrapper that changes network settings. The full source is in `MACSpoofer.ps1` if you want to read it first.

## Troubleshooting

| Problem | Fix |
|---|---|
| "Running scripts is disabled" | Use `MACSpoofer.bat`, or run `Set-ExecutionPolicy -Scope Process Bypass` first |
| Script closes right away | Make sure both files are in the same folder and you clicked Yes on the admin prompt |
| MAC didn't change | Your driver likely doesn't support it. Try a different adapter |
| No adapters listed | Only physical adapters are shown. Virtual adapters (VPN, VM) are skipped |

## Disclaimer

This tool is intended for privacy, testing, and learning on hardware and networks you own or have permission to use. Using it to impersonate another device or bypass access controls on networks you don't own may violate laws or terms of service. You are responsible for how you use it.

