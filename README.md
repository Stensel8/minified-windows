> [!WARNING]
> **I no longer recommend using this tool.**
> It has been superseded by [WinUtil from ChrisTitusTech](https://github.com/ChrisTitusTech/winutil), which is far better at this job and is actively maintained.
> Please use WinUtil instead — see [Recommended Alternatives](#recommended-alternatives) below for details.

---

# minified-windows

Scripts to build a lightweight, fully de-bloated Windows 11 image, powered by **PowerShell**.

This project is a refreshed, minimal, clean, and efficient Windows 11 setup. Built entirely in PowerShell, it is a single-script solution to create slimmed-down Windows 11 ISOs that work with:

- **All Windows 11 versions**
- **Any language or SKU**
- **x64 and ARM64 architectures**

## Recommended Alternatives

**Do not use this tool.** The following alternatives are actively maintained and far more capable:

### ⭐ Option 1 — [WinUtil](https://github.com/ChrisTitusTech/winutil) by ChrisTitusTech *(recommended)*
This is the tool I recommend. It is a powerful, GUI-based PowerShell utility that does everything this project does — and much more. Inside WinUtil there is a dedicated option to create a **minified Windows 11 image**, which is exactly what this project aimed to do. Use that instead.

Run WinUtil with:
```powershell
irm christitus.com/win | iex
```
Then navigate to the **MicroWin** tab to build your minified Windows 11 ISO.

### ⭐ Option 2 — [AtlasOS](https://atlasos.net) *(for extra performance)*
If you have already created a minified Windows 11 ISO (e.g. via WinUtil's MicroWin), you can install **AtlasOS** on top of it for even more performance gains and fine-grained tweaks. AtlasOS is an open-source Windows configuration layer applied via [AME Wizard](https://ameliorated.io/) using a transparent, auditable YAML playbook. I have been gaming on AtlasOS and it is a great choice if you dislike the bloat Microsoft has been pushing into Windows 11.

### [tiny11builder](https://github.com/ntdevlabs/tiny11builder) by ntdevlabs
The original inspiration for this repo. Regularly updated, well-tested, and the go-to tool for building a debloated Windows 11 ISO offline. If you want what this project offered, use this.

## How to Use

1. Download the official Windows 11 ISO:
   [https://www.microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11)

2. Mount the ISO using Windows Explorer.

3. Launch `Minify-Windows.ps1` as **Administrator**:
   ```powershell
   # Standard mode (default)
   .\Minify-Windows.ps1

   # Core mode — maximum removal, use at your own risk
   .\Minify-Windows.ps1 -Mode Core

   # Optionally specify a scratch disk (default: script directory)
   .\Minify-Windows.ps1 -ScratchDisk D
   ```

4. Select the ISO drive letter and image index when prompted.

5. Output: `MinifiedWindows.iso` is created in the script directory.

> Run PowerShell as **Administrator** first:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## Modes

### `-Mode Standard` (default)
Removes bloatware apps and applies privacy/telemetry tweaks. Suitable for general use.

- Removes: Edge, OneDrive, Copilot, Cortana, Teams, Xbox apps, Sticky Notes, To Do, Maps, Weather, News, Bing, Mail, Camera, Solitaire, Clipchamp, Skype, Outlook, DevHome, and more
- Registry tweaks: telemetry, taskbar, sponsored apps, privacy, security hardening
- **No browser will remain** — install one after first boot: `winget install Brave.Brave`

### `-Mode Core`
Everything in Standard, **plus** more aggressive removal. Intended for VMs and test environments.

- Removes optional Windows features: Internet Explorer, Windows Media Player, WordPad, handwriting, speech, OCR
- Strips the component store (WinSxS) to the bare minimum — image cannot be updated
- Removes Windows Recovery Environment (WinRE) — F11 recovery no longer works
- Completely disables Windows Update

> **Both modes produce a non-serviceable image** — Windows Update is unreliable or fully disabled.

## What Gets Removed

See the **Modes** section above for a per-mode breakdown. The full list of removed AppX package prefixes and registry keys is documented inline in [`Minify-Windows.ps1`](Minify-Windows.ps1).

## Registry Tweaks Applied

- Hardware requirement bypass (TPM, Secure Boot, CPU, RAM)
- All telemetry disabled (`AllowTelemetry=0`, `DiagTrack` service disabled, `dmwappushservice` disabled)
- ContentDeliveryManager fully suppressed (no sponsored/suggested apps)
- Copilot disabled via policy
- News and Interests / Widgets disabled
- Chat/Teams icon removed from taskbar
- Edge uninstall entries cleaned from registry
- OneDrive folder sync disabled via policy
- DevHome and Outlook auto-install blocked (UScheduler keys)
- OOBE local account bypass (`BypassNRO`)
- BitLocker device encryption disabled
- Reserved Storage disabled
- Activity History disabled
- Sticky Keys annoyance disabled
- Location access denied by default
- LLMNR (Link-Local Multicast Name Resolution) disabled
- Anonymous SAM enumeration blocked
- Remote Assistance disabled
- Long paths enabled (`LongPathsEnabled=1`)
- Scheduled telemetry tasks removed (Appraiser, CEIP, autochk proxy, QueueReporting, DiskDiagnostic)

## Known Issues

1. **Edge traces** may remain in Settings UI. The app itself is removed.
   > To restore: `winget install edge`

2. **winget may be missing or broken** after a fresh install from this image, since the App Installer package that ships winget may have been removed or broken during debloat.
   > Fix by reinstalling winget via [asheroto/winget-install](https://github.com/asheroto/winget-install):
   > ```powershell
   > Install-Script winget-install -Force
   > winget-install -Force
   > ```

3. **ARM64** may show a harmless error due to missing `OneDriveSetup.exe`.

## Thanks & Sources

This project was built on the shoulders of:

- [ntdevlabs/tiny11builder](https://github.com/ntdevlabs/tiny11builder) - core approach, package list, registry tweaks
- [SimonCropp/WinDebloat](https://github.com/SimonCropp/WinDebloat) - additional registry tweaks and service disabling
- [Atlas-OS/Atlas](https://github.com/Atlas-OS/Atlas) - privacy hardening, security policies, performance tweaks
- [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) - additional debloat patterns and registry keys

## Disclaimer

This project is provided as-is and used **at your own risk**.
The author is **not responsible** for any damage or data loss caused by the use of these scripts.
The author is **not affiliated with Microsoft** or any related entities.
Windows and Windows-related trademarks are owned by **Microsoft Corporation**.
