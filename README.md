# minified-windows

Scripts to build a lightweight, fully de-bloated Windows 11 image — now powered by **PowerShell**.

This project is a refreshed, minimal, clean, and efficient Windows 11 setup. After over a year of silence, the builder script is back — with more flexibility, simplicity, and control. Built entirely in PowerShell, it’s a single-script solution to create slimmed-down Windows 11 ISOs that work with:

- ✅ **All Windows 11 versions**
- ✅ **Any language or SKU**
- ✅ **x64 and ARM64 architectures**

Perfect for virtual machines, test environments, CI pipelines, or anyone who just wants Windows without the extra baggage.

---

## What's New

- Fully rewritten in **PowerShell**
- Works with **any official Windows 11 ISO**
- Uses only **Microsoft-native tools** (DISM + oscdimg)
- Integrated **unattended setup** (OOBE skip + compact mode)
- No third-party apps or downloads required

---

## How to Use

1. Download the official Windows 11 ISO:  
   [https://www.microsoft.com/software-download/windows11](https://www.microsoft.com/software-download/windows11)

2. Mount the ISO using Windows Explorer.

3. Launch the script:
   - Select the ISO drive letter (without the colon)
   - Choose the Windows SKU you want to base the build on

4. Output: A clean `minified-windows.iso` will be created in your working directory.

> Tip: Run PowerShell as **Administrator**, and execute:
> ```powershell
> Set-ExecutionPolicy Unrestricted
> ```

---

## What Gets Removed

### Minified Build:
- Clipchamp, News, Weather, Xbox (except Identity Provider), GetHelp, GetStarted
- Office Hub, Solitaire, PeopleApp, PowerAutomate, ToDo, Alarms
- Mail and Calendar, Feedback Hub, Maps, Sound Recorder, Your Phone
- Media Player, QuickAssist, Internet Explorer, Tablet PC Math
- Microsoft Edge, OneDrive

### Minified Core Build (Use at your own risk):
- Everything above, **plus**:
- Windows Component Store (WinSxS)
- Windows Defender (disabled)
- Windows Update (broken by design)
- WinRE

> ⚠️ Both builds are **non-serviceable** — updates are not guaranteed.
Even though you may receive updates, there is absolutely no guarantee,
since key system components and processes may have been removed.

---

## Features

- Full PowerShell automation
- Uses only Microsoft tools (DISM + oscdimg)
- Built-in unattended XML to bypass Microsoft account
- Optionally enable **.NET Framework 3.5**
- Clean and modular structure

---

## Known Issues

1. **Edge traces** may remain in Settings UI — app is removed.  
   > To restore: `winget install edge`

2. **Outlook and Dev Home** may return via the Microsoft Store.

3. **ARM64** may show a harmless error due to missing `OneDriveSetup.exe`.

---

## Roadmap

- Remove **Copilot**, block deeper **telemetry**
- More control over ads & pre-installed content
- Better language + architecture detection
- Modular features and cleaner flags
- (Maybe) GUI frontend

---

## Thanks To

This tool was inspired by:

- [ntdevlabs](https://github.com/ntdevlabs)
- [Karl-WE](https://github.com/Karl-WE)
- [szepeviktor](https://github.com/szepeviktor)

Much respect to their work in Windows optimization and scripting.

---

## Disclaimer

This project is provided as-is and used **at your own risk**.  
I am **not responsible** for any damage or data loss caused by the use of these scripts.  
I am **not affiliated with Microsoft** or any related entities.  
Windows and Windows-related trademarks are owned by **Microsoft Corporation**.

---

## Ideal Use Cases

- Creating fast, clean VM templates
- Building test setups for software
- Running Windows on older hardware
- Minimalist and clean installs
