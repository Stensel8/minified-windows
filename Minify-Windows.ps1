# Minify-Windows.ps1
# A heavily debloated Windows 11 ISO builder.
# NOT affiliated with ntdev, tiny11, or any other project.
#
# ============================================================
#  DEPRECATED / ARCHIVED
# ============================================================
#  This script is no longer actively maintained.
#  It is kept in the repository for archival purposes only,
#  for people who want to experiment or learn from it.
#
#  Use at your own risk. No support is provided.
# ============================================================
#
# ============================================================
#  WARNING - READ BEFORE USE
# ============================================================
#  This script removes A LOT from Windows 11, including:
#  - Microsoft Edge (NO browser will remain after install!)
#  - Microsoft OneDrive
#  - Microsoft Copilot, Cortana, Teams (personal), MSTeams
#  - Xbox apps, Gaming Overlay, Xbox Identity Provider
#  - Sticky Notes, To Do, Alarms, Maps, Weather, News, Bing
#  - Feedback Hub, Get Help, Get Started, Office Hub
#  - Mixed Reality Portal, Power Automate, Phone Link
#  - Quick Assist, Skype, Solitaire Collection, Clipchamp
#  - Windows Camera, Mail & Calendar, Sound Recorder
#  - Outlook for Windows, Dev Home
#  - [Core] Internet Explorer, Media Player, WordPad
#  - [Core] Windows Recovery Environment (WinRE)
#  - [Core] Windows Update (completely disabled!)
#
#  After installation you will have NO browser.
#  Install one yourself using winget:
#    winget install Brave.Brave          <- recommended
#    winget install Mozilla.Firefox
#    winget install Google.Chrome
#
#  Use -Mode Core for maximum removal.
#  Use -Mode Standard (default) for a balanced result.
# ============================================================

param (
    [ValidatePattern('^[c-zC-Z]$')]
    [string]$ScratchDisk,

    [ValidateSet('Standard', 'Core')]
    [string]$Mode = 'Standard'
)

# Use a separate internal variable so the ValidatePattern on the
# parameter does not block later assignments to a full path.
if (-not $ScratchDisk) {
    $ScratchPath = $PSScriptRoot -replace '[\\]+$', ''
} else {
    $ScratchPath = $ScratchDisk + ":"
}

$logFile = "$ScratchPath\MinifyWindows.log"
function Write-Log {
    param([string]$Message = '', [string]$ForegroundColor = '')
    if ($ForegroundColor) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    } else {
        Write-Host $Message
    }
    Add-Content -LiteralPath $logFile -Value $Message
}

# Check if PowerShell execution is restricted
if ((Get-ExecutionPolicy) -eq 'Restricted') {
    Write-Log "Your current PowerShell Execution Policy is set to Restricted, which prevents scripts from running."
    Write-Log "Do you want to change it to RemoteSigned? (yes/no)"
    $response = Read-Host
    if ($response -eq 'yes') {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Confirm:$false
    } else {
        Write-Log "The script cannot run without changing the execution policy. Exiting..."
        exit
    }
}

# Check and run as admin
$adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
$adminGroup = $adminSID.Translate([System.Security.Principal.NTAccount])
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator
$currentPrincipal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentPrincipal.IsInRole($adminRole)) {
    Write-Log "Restarting script as administrator..."
    $args = "-File `"$($myInvocation.MyCommand.Definition)`" -Mode $Mode"
    if ($ScratchDisk) { $args += " -ScratchDisk $ScratchDisk" }
    Start-Process PowerShell -Verb RunAs -ArgumentList $args
    exit
}

"Minify-Windows log started: $(Get-Date)" | Out-File -LiteralPath $logFile -Encoding UTF8

$Host.UI.RawUI.WindowTitle = "Minify-Windows - Mode: $Mode"
Clear-Host

Write-Log ""
Write-Log "========================================================" -ForegroundColor DarkYellow
Write-Log "  DEPRECATED / ARCHIVED" -ForegroundColor DarkYellow
Write-Log "  This script is no longer maintained." -ForegroundColor DarkYellow
Write-Log "  Use for experimentation only." -ForegroundColor DarkYellow
Write-Log "========================================================" -ForegroundColor DarkYellow
Write-Log ""
Write-Log "========================================================" -ForegroundColor Red
Write-Log "  WARNING" -ForegroundColor Red
Write-Log "========================================================" -ForegroundColor Red
Write-Log ""
Write-Log "  This script removes A LOT from Windows 11!" -ForegroundColor Yellow
Write-Log "  Including:" -ForegroundColor Yellow
Write-Log "   - Microsoft Edge (NO browser after install!)" -ForegroundColor Yellow
Write-Log "   - OneDrive, Cortana, Copilot, Teams, Xbox apps" -ForegroundColor Yellow
Write-Log "   - Sticky Notes, To Do, Maps, Weather, News, Bing" -ForegroundColor Yellow
Write-Log "   - Mail, Camera, Solitaire, Clipchamp, Skype, etc." -ForegroundColor Yellow
if ($Mode -eq 'Core') {
    Write-Log "   - [CORE] IE, Media Player, WordPad, Handwriting" -ForegroundColor Red
    Write-Log "   - [CORE] Windows Recovery Environment (WinRE)" -ForegroundColor Red
    Write-Log "   - [CORE] Windows Update (completely disabled)" -ForegroundColor Red
}
Write-Log ""
Write-Log "  After install you will have NO browser!" -ForegroundColor Cyan
Write-Log "  Install one using winget:" -ForegroundColor Cyan
Write-Log "    winget install Brave.Brave        <- recommended" -ForegroundColor Green
Write-Log "    winget install Mozilla.Firefox" -ForegroundColor Green
Write-Log "    winget install Google.Chrome" -ForegroundColor Green
Write-Log ""
Write-Log "  Mode:        $Mode" -ForegroundColor White
Write-Log "  Scratch dir: $ScratchPath" -ForegroundColor White
Write-Log ""
Write-Log "========================================================" -ForegroundColor Red
Write-Log ""
Write-Log "Press Enter to continue, or close this window to cancel."
Read-Host

$hostArchitecture = $Env:PROCESSOR_ARCHITECTURE
New-Item -ItemType Directory -Force -Path "$ScratchPath\minified-windows\sources" | Out-Null

do {
    $DriveLetter = Read-Host "Enter the drive letter of the mounted Windows 11 ISO (e.g. D)"
    if ($DriveLetter -match '^[c-zC-Z]$') {
        $DriveLetter = $DriveLetter + ":"
        Write-Log "Drive letter set to $DriveLetter"
    } else {
        Write-Log "Invalid drive letter. Please enter a letter between C and Z."
    }
} while ($DriveLetter -notmatch '^[c-zC-Z]:$')

# Determine source format and ask for index ONCE, upfront
if (Test-Path "$DriveLetter\sources\install.wim") {
    # Normal case: install.wim is present on the source drive
    Write-Log "Getting image information:"
    $imageInfo = Get-WindowsImage -ImagePath "$DriveLetter\sources\install.wim" | Out-String
    Write-Host $imageInfo
    Add-Content -LiteralPath $logFile -Value $imageInfo
    $index = Read-Host "Enter the image index"
    $editionName = (Get-WindowsImage -ImagePath "$DriveLetter\sources\install.wim" -Index $index).ImageName
    $esdConverted = $false
} elseif (Test-Path "$DriveLetter\sources\install.esd") {
    # ESD case: convert the selected edition to a single-edition WIM
    Write-Log "Found install.esd - listing available editions:"
    $imageInfo = Get-WindowsImage -ImagePath "$DriveLetter\sources\install.esd" | Out-String
    Write-Host $imageInfo
    Add-Content -LiteralPath $logFile -Value $imageInfo
    $index = Read-Host "Enter the image index"
    $editionName = (Get-WindowsImage -ImagePath "$DriveLetter\sources\install.esd" -Index $index).ImageName
    Write-Log "Converting '$editionName' to install.wim. This may take a while..."
    Export-WindowsImage -SourceImagePath "$DriveLetter\sources\install.esd" -SourceIndex $index -DestinationImagePath "$ScratchPath\minified-windows\sources\install.wim" -Compressiontype Maximum -CheckIntegrity | Out-String | Add-Content -LiteralPath $logFile
    # The resulting WIM always contains exactly one edition at index 1
    $index = 1
    $esdConverted = $true
    Write-Log "Conversion complete."
} else {
    Write-Log "Cannot find Windows installation files on the specified drive."
    Write-Log "Please check the drive letter and try again."
    exit
}

if (-not (Test-Path "$DriveLetter\sources\boot.wim")) {
    Write-Log "Cannot find boot.wim on the specified drive. Exiting."
    exit
}

Write-Log "Copying Windows image..."
Copy-Item -Path "$DriveLetter\*" -Destination "$ScratchPath\minified-windows" -Recurse -Force | Out-Null
# Clean up any install.esd that was copied (we already have install.wim)
Set-ItemProperty -Path "$ScratchPath\minified-windows\sources\install.esd" -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
Remove-Item "$ScratchPath\minified-windows\sources\install.esd" -ErrorAction SilentlyContinue
Write-Log "Copy complete!"
Start-Sleep -Seconds 2
Clear-Host

Write-Log "Mounting Windows image: $editionName. This may take a while..."
$wimFilePath = "$ScratchPath\minified-windows\sources\install.wim"
& takeown "/F" $wimFilePath 2>&1 | Add-Content -LiteralPath $logFile
& icacls $wimFilePath "/grant" "$($adminGroup.Value):(F)" 2>&1 | Add-Content -LiteralPath $logFile
try {
    Set-ItemProperty -Path $wimFilePath -Name IsReadOnly -Value $false -ErrorAction Stop
} catch { }
New-Item -ItemType Directory -Force -Path "$ScratchPath\scratchdir" > $null
Mount-WindowsImage -ImagePath "$ScratchPath\minified-windows\sources\install.wim" -Index $index -Path "$ScratchPath\scratchdir" | Out-String | Add-Content -LiteralPath $logFile

$imageIntl = & dism /English /Get-Intl "/Image:$($ScratchPath)\scratchdir"
$languageLine = $imageIntl -split '\n' | Where-Object { $_ -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})' }
if ($languageLine) {
    $languageCode = $Matches[1]
    Write-Log "Default system UI language code: $languageCode"
} else {
    Write-Log "Language code not found, defaulting to en-US."
    $languageCode = "en-US"
}

$imageInfo = & dism /English /Get-WimInfo "/wimFile:$($ScratchPath)\minified-windows\sources\install.wim" "/index:$index"
$lines = $imageInfo -split '\r?\n'
foreach ($line in $lines) {
    if ($line -like '*Architecture : *') {
        $architecture = $line -replace 'Architecture : ', ''
        if ($architecture -eq 'x64') { $architecture = 'amd64' }
        Write-Log "Architecture: $architecture"
        break
    }
}
if (-not $architecture) { Write-Log "Architecture information not found." }

# ============================================================
# STEP 1: Remove provisioned AppX packages
# ============================================================
Write-Log ""
Write-Log "=== Removing built-in apps ===" -ForegroundColor Cyan

$packagePrefixes = @(
    'Clipchamp.Clipchamp_',
    'Microsoft.BingNews_',
    'Microsoft.BingSearch_',
    'Microsoft.BingWeather_',
    'Microsoft.BingFinance_',
    'Microsoft.BingSports_',
    'Microsoft.Copilot_',
    'Microsoft.GamingApp_',
    'Microsoft.GetHelp_',
    'Microsoft.Getstarted_',
    'Microsoft.MicrosoftOfficeHub_',
    'Microsoft.MicrosoftSolitaireCollection_',
    'Microsoft.MicrosoftStickyNotes_',
    'Microsoft.MixedReality.Portal_',
    'Microsoft.OutlookForWindows_',
    'Microsoft.Paint3D_',
    'Microsoft.People_',
    'Microsoft.Photos_',
    'Microsoft.PowerAutomateDesktop_',
    'Microsoft.ScreenSketch_',
    'Microsoft.SkypeApp_',
    'Microsoft.Todos_',
    'Microsoft.Whiteboard_',
    'Microsoft.Windows.DevHome_',
    'Microsoft.WindowsAlarms_',
    'Microsoft.WindowsCamera_',
    'microsoft.windowscommunicationsapps_',
    'Microsoft.WindowsFeedbackHub_',
    'Microsoft.WindowsMaps_',
    'Microsoft.WindowsSoundRecorder_',
    'Microsoft.Xbox.TCUI_',
    'Microsoft.XboxGamingOverlay_',
    'Microsoft.XboxGameOverlay_',
    'Microsoft.XboxIdentityProvider_',
    'Microsoft.XboxSpeechToTextOverlay_',
    'Microsoft.YourPhone_',
    'Microsoft.ZuneMusic_',
    'Microsoft.ZuneVideo_',
    'MicrosoftCorporationII.MicrosoftFamily_',
    'MicrosoftCorporationII.QuickAssist_',
    'MicrosoftTeams_',
    'MicrosoftWindows.Client.WebExperience_',
    'MSTeams_',
    'Microsoft.549981C3F5F10_'
)

if ($Mode -eq 'Core') {
    $packagePrefixes += @(
        'Microsoft.Windows.PeopleExperienceHost_',
        'Microsoft.Windows.PinningConfirmationDialog_',
        'Windows.CBSPreview_'
    )
}

$allProvisioned = Get-AppxProvisionedPackage -Path "$ScratchPath\scratchdir"
$toRemove = $allProvisioned | Where-Object {
    $name = $_.PackageName
    $packagePrefixes | Where-Object { $name -like "$_*" }
}
Write-Log "Found $($toRemove.Count) packages to remove."
$toRemove | ForEach-Object {
    Write-Log "Removing: $($_.DisplayName)"
    $_ | Remove-AppxProvisionedPackage -ErrorAction SilentlyContinue | Out-String | Add-Content -LiteralPath $logFile
}

# ============================================================
# STEP 2: Remove Edge and OneDrive
# ============================================================
Write-Log ""
Write-Log "=== Removing Microsoft Edge ===" -ForegroundColor Cyan
Write-Log "NOTE: No browser will remain! After install, run: winget install Brave.Brave" -ForegroundColor Yellow

Remove-Item -Path "$ScratchPath\scratchdir\Program Files (x86)\Microsoft\Edge" -Recurse -Force | Out-Null
Remove-Item -Path "$ScratchPath\scratchdir\Program Files (x86)\Microsoft\EdgeUpdate" -Recurse -Force | Out-Null
Remove-Item -Path "$ScratchPath\scratchdir\Program Files (x86)\Microsoft\EdgeCore" -Recurse -Force | Out-Null

if ($architecture -eq 'amd64') {
    $folderPaths = Get-ChildItem -Path "$ScratchPath\scratchdir\Windows\WinSxS" -Filter "amd64_microsoft-edge-webview_31bf3856ad364e35*" -Directory | Select-Object -ExpandProperty FullName
} elseif ($architecture -eq 'arm64') {
    $folderPaths = Get-ChildItem -Path "$ScratchPath\scratchdir\Windows\WinSxS" -Filter "arm64_microsoft-edge-webview_31bf3856ad364e35*" -Directory | Select-Object -ExpandProperty FullName
} else {
    $folderPaths = @()
}
foreach ($fp in $folderPaths) {
    & takeown /f $fp /r /d y 2>&1 | Add-Content -LiteralPath $logFile
    & icacls $fp "/grant" "Administrators:F" /T /C 2>&1 | Add-Content -LiteralPath $logFile
    & attrib -r -s -h "$fp\*" /s /d 2>&1 | Add-Content -LiteralPath $logFile
    & cmd /c rmdir /s /q "`"$fp`"" 2>&1 | Add-Content -LiteralPath $logFile
}

& takeown /f "$ScratchPath\scratchdir\Windows\System32\Microsoft-Edge-Webview" /r 2>&1 | Add-Content -LiteralPath $logFile
& icacls "$ScratchPath\scratchdir\Windows\System32\Microsoft-Edge-Webview" /grant "$($adminGroup.Value):(F)" /T /C 2>&1 | Add-Content -LiteralPath $logFile
Remove-Item -Path "$ScratchPath\scratchdir\Windows\System32\Microsoft-Edge-Webview" -Recurse -Force | Out-Null

Write-Log "=== Removing OneDrive ===" -ForegroundColor Cyan
& takeown /f "$ScratchPath\scratchdir\Windows\System32\OneDriveSetup.exe" 2>&1 | Add-Content -LiteralPath $logFile
& icacls "$ScratchPath\scratchdir\Windows\System32\OneDriveSetup.exe" /grant "$($adminGroup.Value):(F)" /T /C 2>&1 | Add-Content -LiteralPath $logFile
Remove-Item -Path "$ScratchPath\scratchdir\Windows\System32\OneDriveSetup.exe" -Force | Out-Null

# ============================================================
# STEP 3: [Core] Remove Windows packages (optional features)
# ============================================================
if ($Mode -eq 'Core') {
    Write-Log ""
    Write-Log "=== [Core] Removing Windows packages ===" -ForegroundColor Magenta
    Start-Sleep -Seconds 1

    $scratchDir = "$ScratchPath\scratchdir"
    $packagePatterns = @(
        "Microsoft-Windows-InternetExplorer-Optional-Package~31bf3856ad364e35",
        "Microsoft-Windows-Kernel-LA57-FoD-Package~31bf3856ad364e35~amd64",
        "Microsoft-Windows-LanguageFeatures-Handwriting-$languageCode-Package~31bf3856ad364e35",
        "Microsoft-Windows-LanguageFeatures-OCR-$languageCode-Package~31bf3856ad364e35",
        "Microsoft-Windows-LanguageFeatures-Speech-$languageCode-Package~31bf3856ad364e35",
        "Microsoft-Windows-LanguageFeatures-TextToSpeech-$languageCode-Package~31bf3856ad364e35",
        "Microsoft-Windows-MediaPlayer-Package~31bf3856ad364e35",
        "Microsoft-Windows-Wallpaper-Content-Extended-FoD-Package~31bf3856ad364e35",
        "Windows-Defender-Client-Package~31bf3856ad364e35~",
        "Microsoft-Windows-WordPad-FoD-Package~",
        "Microsoft-Windows-TabletPCMath-Package~",
        "Microsoft-Windows-StepsRecorder-Package~"
    )

    $allPackages = Get-WindowsPackage -Path $scratchDir | Where-Object { $_.PackageState -eq 'Installed' }

    foreach ($pattern in $packagePatterns) {
        $packagesToRemove = $allPackages | Where-Object { $_.PackageName -like "$pattern*" }
        foreach ($package in $packagesToRemove) {
            Write-Log "Removing: $($package.PackageName)"
            try {
                Remove-WindowsPackage -Path $scratchDir -PackageName $package.PackageName -ErrorAction Stop | Out-String | Add-Content -LiteralPath $logFile
            } catch {
                Write-Log "Warning: Could not remove $($package.PackageName): $_" -ForegroundColor Yellow
            }
        }
    }

    Write-Log ""
    $enableDotNet = Read-Host "Enable .NET 3.5? (y/n)"
    if ($enableDotNet -eq 'y') {
        Write-Log "Enabling .NET 3.5..."
        & dism "/image:$scratchDir" /enable-feature /featurename:NetFX3 /All "/source:$ScratchPath\minified-windows\sources\sxs" 2>&1 | Add-Content -LiteralPath $logFile
    }

    Write-Log ""
    Write-Log "=== [Core] Removing Windows Recovery Environment (WinRE) ===" -ForegroundColor Magenta
    & takeown /f "$ScratchPath\scratchdir\Windows\System32\Recovery" /r 2>&1 | Add-Content -LiteralPath $logFile
    & icacls "$ScratchPath\scratchdir\Windows\System32\Recovery" /grant "Administrators:F" /T /C 2>&1 | Add-Content -LiteralPath $logFile
    Remove-Item -Path "$ScratchPath\scratchdir\Windows\System32\Recovery\winre.wim" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path "$ScratchPath\scratchdir\Windows\System32\Recovery\winre.wim" -ItemType File -Force | Out-Null

    Write-Log ""
    Write-Log "=== [Core] Cleaning WinSxS (minimal component store) ===" -ForegroundColor Magenta
    Write-Log "Taking ownership of WinSxS. This may take a long time..."
    & takeown /f "$ScratchPath\scratchdir\Windows\WinSxS" /r 2>&1 | Out-Null
    & icacls "$ScratchPath\scratchdir\Windows\WinSxS" /grant "$($adminGroup.Value):(F)" /T /C 2>&1 | Out-Null

    $sourceDirectory = "$ScratchPath\scratchdir\Windows\WinSxS"
    $destinationDirectory = "$ScratchPath\scratchdir\Windows\WinSxS_edit"
    New-Item -Path $destinationDirectory -ItemType Directory -Force | Out-Null

    if ($architecture -eq "amd64") {
        $dirsToCopy = @(
            "x86_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "x86_microsoft.windows.gdiplus_6595b64144ccf1df_*",
            "x86_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
            "x86_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
            "x86_microsoft-windows-s..ngstack-onecorebase_31bf3856ad364e35_*",
            "x86_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*",
            "x86_microsoft-windows-servicingstack_31bf3856ad364e35_*",
            "x86_microsoft-windows-servicingstack-inetsrv_*",
            "x86_microsoft-windows-servicingstack-onecore_*",
            "amd64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
            "amd64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
            "amd64_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*",
            "amd64_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "amd64_microsoft.windows.gdiplus_6595b64144ccf1df_*",
            "amd64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
            "amd64_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
            "amd64_microsoft-windows-s..stack-inetsrv-extra_31bf3856ad364e35_*",
            "amd64_microsoft-windows-s..stack-msg.resources_31bf3856ad364e35_*",
            "amd64_microsoft-windows-s..stack-termsrv-extra_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*",
            "amd64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*",
            "Catalogs", "FileMaps", "Fusion", "InstallTemp", "Manifests",
            "x86_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
            "x86_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
            "x86_microsoft.windows.c..-controls.resources_6595b64144ccf1df_*"
        )
    } elseif ($architecture -eq "arm64") {
        $dirsToCopy = @(
            "arm64_microsoft-windows-servicingstack-onecore_31bf3856ad364e35_*",
            "arm64_microsoft.vc80.crt_1fc8b3b9a1e18e3b_*",
            "arm64_microsoft.vc90.crt_1fc8b3b9a1e18e3b_*",
            "arm64_microsoft.windows.common-controls_6595b64144ccf1df_*",
            "arm64_microsoft.windows.gdiplus_6595b64144ccf1df_*",
            "arm64_microsoft.windows.i..utomation.proxystub_6595b64144ccf1df_*",
            "arm64_microsoft.windows.isolationautomation_6595b64144ccf1df_*",
            "arm64_microsoft-windows-servicingstack_31bf3856ad364e35_*",
            "arm64_microsoft-windows-servicingstack-inetsrv_31bf3856ad364e35_*",
            "arm64_microsoft-windows-servicingstack-msg_31bf3856ad364e35_*",
            "Catalogs", "FileMaps", "Fusion", "InstallTemp", "Manifests"
        )
    } else {
        $dirsToCopy = @()
    }

    Write-Log "Copying required WinSxS entries..."
    foreach ($dir in $dirsToCopy) {
        $sourceDirs = Get-ChildItem -Path $sourceDirectory -Filter $dir -Directory -ErrorAction SilentlyContinue
        foreach ($sourceDir in $sourceDirs) {
            $destDir = Join-Path -Path $destinationDirectory -ChildPath $sourceDir.Name
            Copy-Item -Path $sourceDir.FullName -Destination $destDir -Recurse -Force
        }
        $sourceItem = Join-Path -Path $sourceDirectory -ChildPath $dir
        if ((Test-Path $sourceItem) -and (Get-Item $sourceItem).PSIsContainer) {
            $destItem = Join-Path -Path $destinationDirectory -ChildPath $dir
            if (-not (Test-Path $destItem)) {
                Copy-Item -Path $sourceItem -Destination $destItem -Recurse -Force
            }
        }
    }

    Write-Log "Deleting WinSxS..."
    Remove-Item -Path "$ScratchPath\scratchdir\Windows\WinSxS" -Recurse -Force
    Rename-Item -Path "$ScratchPath\scratchdir\Windows\WinSxS_edit" -NewName "WinSxS"
}

Write-Log ""
Write-Log "Removal complete!"
Start-Sleep -Seconds 2
Clear-Host

# ============================================================
# STEP 4: Load registry hives and apply tweaks
# ============================================================
Write-Log "=== Loading registry ===" -ForegroundColor Cyan
reg load HKLM\zCOMPONENTS "$ScratchPath\scratchdir\Windows\System32\config\COMPONENTS" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zDEFAULT "$ScratchPath\scratchdir\Windows\System32\config\default" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zNTUSER "$ScratchPath\scratchdir\Users\Default\ntuser.dat" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zSOFTWARE "$ScratchPath\scratchdir\Windows\System32\config\SOFTWARE" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zSYSTEM "$ScratchPath\scratchdir\Windows\System32\config\SYSTEM" 2>&1 | Add-Content -LiteralPath $logFile

# -- Bypass hardware requirements --
Write-Log "Bypassing system requirements..."
& reg add 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' /v SV1 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' /v SV2 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' /v SV1 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' /v SV2 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassCPUCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassRAMCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassSecureBootCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassStorageCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassTPMCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\MoSetup' /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f | Out-Null

# -- Disable sponsored / silently installed apps --
Write-Log "Disabling sponsored and pre-installed apps..."
& reg add 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v ContentDeliveryAllowed /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' /v ConfigureStartPins /t REG_SZ /d '{"pinnedList": [{}]}' /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v FeatureManagementEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v OemPreInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v PreInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v PreInstalledAppsEverEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SilentInstalledAppsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SoftLandingEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContentEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-310093Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-338388Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-338389Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-338393Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-353694Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-353696Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SubscribedContent-353698Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v RotatingLockScreenOverlayEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v SystemPaneSuggestionsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' /v DisablePushToInstall /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' /v DontOfferThroughWUAU /t REG_DWORD /d 1 /f | Out-Null
& reg delete 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions' /f | Out-Null
& reg delete 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps' /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' /v DisableConsumerAccountStateContent /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' /v DisableCloudOptimizedContent /t REG_DWORD /d 1 /f | Out-Null

# -- Enable local accounts at OOBE --
Write-Log "Enabling local accounts at OOBE..."
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' /v BypassNRO /t REG_DWORD /d 1 /f | Out-Null
Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ScratchPath\scratchdir\Windows\System32\Sysprep\autounattend.xml" -Force -ErrorAction SilentlyContinue | Out-Null

# -- Miscellaneous --
Write-Log "Disabling reserved storage..."
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' /v ShippedWithReserves /t REG_DWORD /d 0 /f | Out-Null
Write-Log "Disabling automatic BitLocker device encryption..."
& reg add 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' /v PreventDeviceEncryption /t REG_DWORD /d 1 /f | Out-Null

# -- Taskbar cleanup --
Write-Log "Cleaning up taskbar (Chat, Copilot, Widgets, Search, Task View)..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' /v ChatIcon /t REG_DWORD /d 3 /f | Out-Null
& reg add 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v TaskbarMn /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v ShowCopilotButton /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v TaskbarDa /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v ShowTaskViewButton /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v ShowVisualSearchDesktopIcon /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Search' /v SearchboxTaskbarMode /t REG_DWORD /d 0 /f | Out-Null

# -- Show file extensions --
Write-Log "Enabling visible file extensions..."
& reg add 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v HideFileExt /t REG_DWORD /d 0 /f | Out-Null

# -- Remove Edge registry entries --
Write-Log "Removing Edge registry entries..."
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f | Out-Null
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update" /f | Out-Null

# -- Edge policies (WinDebloat) --
Write-Log "Applying Edge policies..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' /v WebWidgetAllowed /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' /v HubsSidebarEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' /v ShowRecommendationsEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' /v StartupBoostEnabled /t REG_DWORD /d 0 /f | Out-Null

# -- OneDrive policy --
Write-Log "Disabling OneDrive folder backup..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive' /v DisableFileSyncNGSC /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Explorer' /v ShowCloudFilesInQuickAccess /t REG_DWORD /d 0 /f | Out-Null

# -- Disable telemetry and tracking --
Write-Log "Disabling telemetry and tracking..."
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' /v Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' /v HasAccepted /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' /v Enabled /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' /v RestrictImplicitInkCollection /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' /v RestrictImplicitTextCollection /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' /v HarvestContacts /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Microsoft\Siuf\Rules' /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' /v MaxTelemetryAllowed /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\System' /v EnableActivityFeed /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\System' /v PublishUserActivities /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\System' /v UploadUserActivities /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' /v Start /t REG_DWORD /d 4 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Services\DiagTrack' /v Start /t REG_DWORD /d 4 /f | Out-Null
# .NET CLI telemetry opt-out (WinDebloat)
& reg add 'HKLM\zSYSTEM\ControlSet001\Control\Session Manager\Environment' /v DOTNET_CLI_TELEMETRY_OPTOUT /t REG_SZ /d 'true' /f | Out-Null

# -- Block DevHome and Outlook auto-install --
Write-Log "Blocking DevHome and Outlook auto-install..."
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' /v workCompleted /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' /v workCompleted /t REG_DWORD /d 1 /f | Out-Null
& reg delete 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' /f | Out-Null
& reg delete 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate' /f | Out-Null

# -- Disable Copilot --
Write-Log "Disabling Copilot..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Communications' /v ConfigureChatAutoInstall /t REG_DWORD /d 0 /f | Out-Null
# Remove "Ask Copilot" from Explorer context menu (WinDebloat)
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' /v '{CB3B0003-8088-4EDE-8769-8B354AB2FF8C}' /t REG_SZ /d '' /f | Out-Null
# Disable Copilot/AI in Notepad (WinDebloat)
& reg add 'HKLM\zSOFTWARE\Policies\WindowsNotepad' /v DisableAIFeatures /t REG_DWORD /d 1 /f | Out-Null

# -- Disable News, Widgets, and Feeds --
Write-Log "Disabling News, Widgets, and Feeds..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Feeds' /v EnableFeeds /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Dsh' /v AllowNewsAndInterests /t REG_DWORD /d 0 /f | Out-Null

# -- Start Menu cleanup --
Write-Log "Cleaning up Start Menu (recommendations, Bing search, suggestions)..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' /v HideRecommendedSection /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Policies\Microsoft\Windows\Explorer' /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Software\Policies\Microsoft\Windows\Explorer' /v ShowRunAsDifferentUserInStart /t REG_DWORD /d 1 /f | Out-Null

# -- Context menu cleanup (WinDebloat) --
Write-Log "Removing unnecessary context menu entries..."
# Remove "Give access to"
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked' /v '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}' /t REG_SZ /d '' /f | Out-Null
# Remove 3D Objects from Explorer sidebar
& reg delete 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}' /f | Out-Null
# Remove Spotlight/wallpaper context menu items
& reg delete 'HKLM\zNTUSER\Software\Classes\DesktopBackground\Shell\.SpotlightLearnMore' /f | Out-Null
& reg delete 'HKLM\zNTUSER\Software\Classes\DesktopBackground\Shell\.SpotlightNextImage' /f | Out-Null

# -- Security hardening --
Write-Log "Applying security hardening..."
& reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows NT\DNSClient' /v EnableMulticast /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Control\Lsa' /v RestrictAnonymousSAM /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Control\Remote Assistance' /v fAllowFullControl /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Control\Remote Assistance' /v fAllowToGetHelp /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Control\FileSystem' /v LongPathsEnabled /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zNTUSER\Control Panel\Accessibility\StickyKeys' /v Flags /t REG_SZ /d '506' /f | Out-Null
& reg add 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' /v Value /t REG_SZ /d 'Deny' /f | Out-Null

# -- Disable additional unnecessary services (WinDebloat) --
Write-Log "Disabling unnecessary services..."
& reg add 'HKLM\zSYSTEM\ControlSet001\Services\MapsBroker' /v Start /t REG_DWORD /d 4 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Services\PcaSvc' /v Start /t REG_DWORD /d 4 /f | Out-Null
& reg add 'HKLM\zSYSTEM\ControlSet001\Services\SharedAccess' /v Start /t REG_DWORD /d 4 /f | Out-Null

# ============================================================
# STEP 5: Remove scheduled tasks
# ============================================================
Write-Log ""
Write-Log "=== Removing scheduled tasks ===" -ForegroundColor Cyan

function Enable-Privilege {
    param(
        [ValidateSet(
            "SeAssignPrimaryTokenPrivilege", "SeAuditPrivilege", "SeBackupPrivilege",
            "SeChangeNotifyPrivilege", "SeCreateGlobalPrivilege", "SeCreatePagefilePrivilege",
            "SeCreatePermanentPrivilege", "SeCreateSymbolicLinkPrivilege", "SeCreateTokenPrivilege",
            "SeDebugPrivilege", "SeEnableDelegationPrivilege", "SeImpersonatePrivilege",
            "SeIncreaseBasePriorityPrivilege", "SeIncreaseQuotaPrivilege", "SeIncreaseWorkingSetPrivilege",
            "SeLoadDriverPrivilege", "SeLockMemoryPrivilege", "SeMachineAccountPrivilege",
            "SeManageVolumePrivilege", "SeProfileSingleProcessPrivilege", "SeRelabelPrivilege",
            "SeRemoteShutdownPrivilege", "SeRestorePrivilege", "SeSecurityPrivilege",
            "SeShutdownPrivilege", "SeSyncAgentPrivilege", "SeSystemEnvironmentPrivilege",
            "SeSystemProfilePrivilege", "SeSystemtimePrivilege", "SeTakeOwnershipPrivilege",
            "SeTcbPrivilege", "SeTimeZonePrivilege", "SeTrustedCredManAccessPrivilege",
            "SeUndockPrivilege", "SeUnsolicitedInputPrivilege")]
        $Privilege,
        $ProcessId = $pid,
        [Switch] $Disable
    )
    $definition = @'
using System;
using System.Runtime.InteropServices;

public class AdjPriv {
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,
        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid {
        public int Count;
        public long Luid;
        public int Attr;
    }
    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int SE_PRIVILEGE_DISABLED = 0x00000000;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    public static bool EnablePrivilege(long processHandle, string privilege, bool disable) {
        bool retVal;
        TokPriv1Luid tp;
        IntPtr hproc = new IntPtr(processHandle);
        IntPtr htok = IntPtr.Zero;
        retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
        tp.Count = 1;
        tp.Luid = 0;
        tp.Attr = disable ? SE_PRIVILEGE_DISABLED : SE_PRIVILEGE_ENABLED;
        retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
        retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
        return retVal;
    }
}
'@
    $processHandle = (Get-Process -id $ProcessId).Handle
    $type = Add-Type $definition -PassThru
    $type[0]::EnablePrivilege($processHandle, $Privilege, $Disable)
}

Enable-Privilege SeTakeOwnershipPrivilege | Out-String | Add-Content -LiteralPath $logFile

$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    "zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks",
    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
    [System.Security.AccessControl.RegistryRights]::TakeOwnership)
$regACL = $regKey.GetAccessControl()
$regACL.SetOwner($adminGroup)
$regKey.SetAccessControl($regACL)
$regKey.Close()

$regKey = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
    "zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks",
    [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
    [System.Security.AccessControl.RegistryRights]::ChangePermissions)
$regACL = $regKey.GetAccessControl()
$regRule = New-Object System.Security.AccessControl.RegistryAccessRule ($adminGroup, "FullControl", "ContainerInherit", "None", "Allow")
$regACL.SetAccessRule($regRule)
$regKey.SetAccessControl($regACL)
$regKey.Close()

Write-Log "Removing Application Compatibility Appraiser..."
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0600DD45-FAF2-4131-A006-0B17509B9F78}" /f | Out-Null
Write-Log "Removing Customer Experience Improvement Program..."
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{4738DE7A-BCC1-4E2D-B1B0-CADB044BFA81}" /f | Out-Null
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{6FAC31FA-4A85-4E64-BFD5-2154FF4594B3}" /f | Out-Null
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{FC931F16-B50A-472E-B061-B6F79A71EF59}" /f | Out-Null
Write-Log "Removing Program Data Updater..."
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{0671EB05-7D95-4153-A32B-1426B9FE61DB}" /f | Out-Null
Write-Log "Removing autochk proxy..."
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{87BF85F4-2CE1-4160-96EA-52F554AA28A2}" /f | Out-Null
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{8A9C643C-3D74-4099-B6BD-9C6D170898B1}" /f | Out-Null
Write-Log "Removing QueueReporting..."
reg delete "HKEY_LOCAL_MACHINE\zSOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\TaskCache\Tasks\{E3176A65-4E44-4ED3-AA73-3283660ACB9C}" /f | Out-Null

# ============================================================
# STEP 6: [Core] Completely disable Windows Update
# ============================================================
if ($Mode -eq 'Core') {
    Write-Log ""
    Write-Log "=== [Core] Disabling Windows Update ===" -ForegroundColor Magenta
    & reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v StopWUPostOOBE1 /t REG_SZ /d 'net stop wuauserv' /f | Out-Null
    & reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v StopWUPostOOBE2 /t REG_SZ /d 'sc stop wuauserv' /f | Out-Null
    & reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v StopWUPostOOBE3 /t REG_SZ /d 'sc config wuauserv start= disabled' /f | Out-Null
    & reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v DisableWUPostOOBE1 /t REG_SZ /d 'reg add HKLM\SYSTEM\CurrentControlSet\Services\wuauserv /v Start /t REG_DWORD /d 4 /f' /f | Out-Null
    & reg add "HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v DisableWUPostOOBE2 /t REG_SZ /d 'reg add HKLM\SYSTEM\ControlSet001\Services\wuauserv /v Start /t REG_DWORD /d 4 /f' /f | Out-Null
    & reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' /v DoNotConnectToWindowsUpdateInternetLocations /t REG_DWORD /d 1 /f | Out-Null
    & reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' /v DisableWindowsUpdateAccess /t REG_DWORD /d 1 /f | Out-Null
    & reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' /v WUServer /t REG_SZ /d 'localhost' /f | Out-Null
    & reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' /v WUStatusServer /t REG_SZ /d 'localhost' /f | Out-Null
    & reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' /v UpdateServiceUrlAlternate /t REG_SZ /d 'localhost' /f | Out-Null
    & reg add 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' /v UseWUServer /t REG_DWORD /d 1 /f | Out-Null
    & reg add 'HKLM\zSYSTEM\ControlSet001\Services\wuauserv' /v Start /t REG_DWORD /d 4 /f | Out-Null
}

# ============================================================
# STEP 7: Unload registry hives
# ============================================================
Write-Log ""
Write-Log "=== Unloading registry ===" -ForegroundColor Cyan
reg unload HKLM\zCOMPONENTS 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zDEFAULT 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zNTUSER 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zSOFTWARE 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zSYSTEM 2>&1 | Add-Content -LiteralPath $logFile

Write-Log "All tweaks applied!"
Write-Log ""
Write-Log "=== Cleaning up image ===" -ForegroundColor Cyan
Repair-WindowsImage -Path "$ScratchPath\scratchdir" -StartComponentCleanup -ResetBase | Out-String | Add-Content -LiteralPath $logFile
Write-Log "Cleanup complete."

Write-Log "Unmounting image..."
Dismount-WindowsImage -Path "$ScratchPath\scratchdir" -Save | Out-String | Add-Content -LiteralPath $logFile

Write-Log "Exporting image..."
Export-WindowsImage -SourceImagePath "$ScratchPath\minified-windows\sources\install.wim" -SourceIndex $index -DestinationImagePath "$ScratchPath\minified-windows\sources\install2.wim" -CompressionType Fast | Out-String | Add-Content -LiteralPath $logFile
Remove-Item -Path "$ScratchPath\minified-windows\sources\install.wim" -Force | Out-Null
Rename-Item -Path "$ScratchPath\minified-windows\sources\install2.wim" -NewName "install.wim" | Out-Null

Write-Log "install.wim complete. Processing boot.wim..."
Start-Sleep -Seconds 2
Clear-Host

# ============================================================
# STEP 8: Process boot.wim
# ============================================================
Write-Log "=== Mounting boot.wim ===" -ForegroundColor Cyan
$bootWimPath = "$ScratchPath\minified-windows\sources\boot.wim"
& takeown "/F" $bootWimPath 2>&1 | Add-Content -LiteralPath $logFile
& icacls $bootWimPath "/grant" "$($adminGroup.Value):(F)" 2>&1 | Add-Content -LiteralPath $logFile
Set-ItemProperty -Path $bootWimPath -Name IsReadOnly -Value $false
Mount-WindowsImage -ImagePath $bootWimPath -Index 2 -Path "$ScratchPath\scratchdir" | Out-String | Add-Content -LiteralPath $logFile

Write-Log "Loading registry (boot image)..."
reg load HKLM\zCOMPONENTS "$ScratchPath\scratchdir\Windows\System32\config\COMPONENTS" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zDEFAULT "$ScratchPath\scratchdir\Windows\System32\config\default" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zNTUSER "$ScratchPath\scratchdir\Users\Default\ntuser.dat" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zSOFTWARE "$ScratchPath\scratchdir\Windows\System32\config\SOFTWARE" 2>&1 | Add-Content -LiteralPath $logFile
reg load HKLM\zSYSTEM "$ScratchPath\scratchdir\Windows\System32\config\SYSTEM" 2>&1 | Add-Content -LiteralPath $logFile

Write-Log "Bypassing system requirements (setup image)..."
& reg add 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' /v SV1 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' /v SV2 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' /v SV1 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' /v SV2 /t REG_DWORD /d 0 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassCPUCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassRAMCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassSecureBootCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassStorageCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\LabConfig' /v BypassTPMCheck /t REG_DWORD /d 1 /f | Out-Null
& reg add 'HKLM\zSYSTEM\Setup\MoSetup' /v AllowUpgradesWithUnsupportedTPMOrCPU /t REG_DWORD /d 1 /f | Out-Null

Write-Log "Unloading registry (boot image)..."
reg unload HKLM\zCOMPONENTS 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zDEFAULT 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zNTUSER 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zSOFTWARE 2>&1 | Add-Content -LiteralPath $logFile
reg unload HKLM\zSYSTEM 2>&1 | Add-Content -LiteralPath $logFile

Write-Log "Unmounting boot.wim..."
Dismount-WindowsImage -Path "$ScratchPath\scratchdir" -Save | Out-String | Add-Content -LiteralPath $logFile

# ============================================================
# STEP 9: Create ISO
# ============================================================
Clear-Host
Write-Log "=== Creating ISO ===" -ForegroundColor Cyan

Write-Log "Copying autounattend.xml for local account bypass..."
Copy-Item -Path "$PSScriptRoot\autounattend.xml" -Destination "$ScratchPath\minified-windows\autounattend.xml" -Force -ErrorAction SilentlyContinue | Out-Null

$ADKDepTools = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$hostArchitecture\Oscdimg"
$localOSCDIMGPath = "$PSScriptRoot\oscdimg.exe"

if ([System.IO.Directory]::Exists($ADKDepTools)) {
    Write-Log "Using oscdimg.exe from system ADK."
    $OSCDIMG = "$ADKDepTools\oscdimg.exe"
} else {
    Write-Log "ADK not found. Using bundled oscdimg.exe."
    $url = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"
    if (-not (Test-Path -Path $localOSCDIMGPath)) {
        Write-Log "Downloading oscdimg.exe..."
        Invoke-WebRequest -Uri $url -OutFile $localOSCDIMGPath
        if (-not (Test-Path $localOSCDIMGPath)) {
            Write-Error "Failed to download oscdimg.exe."
            exit 1
        }
    }
    $OSCDIMG = $localOSCDIMGPath
}

$outputIso = "$PSScriptRoot\MinifiedWindows.iso"
& "$OSCDIMG" '-m' '-o' '-u2' '-udfver102' `
    "-bootdata:2#p0,e,b$ScratchPath\minified-windows\boot\etfsboot.com#pEF,e,b$ScratchPath\minified-windows\efi\microsoft\boot\efisys.bin" `
    "$ScratchPath\minified-windows" `
    "$outputIso" 2>&1 | Add-Content -LiteralPath $logFile

Write-Log ""
Write-Log "========================================================" -ForegroundColor Green
Write-Log "  Done! ISO saved as:" -ForegroundColor Green
Write-Log "  $outputIso" -ForegroundColor Green
Write-Log ""
Write-Log "  REMINDER: no browser is installed!" -ForegroundColor Yellow
Write-Log "  After first boot, install one with winget:" -ForegroundColor Yellow
Write-Log "    winget install Brave.Brave        <- recommended" -ForegroundColor Cyan
Write-Log "    winget install Mozilla.Firefox" -ForegroundColor Cyan
Write-Log "    winget install Google.Chrome" -ForegroundColor Cyan
Write-Log "========================================================" -ForegroundColor Green
Write-Log ""

Read-Host "Press Enter to clean up and exit"

Write-Log "Cleaning up..."
Remove-Item -Path "$ScratchPath\minified-windows" -Recurse -Force | Out-Null
Remove-Item -Path "$ScratchPath\scratchdir" -Recurse -Force | Out-Null

Add-Content -LiteralPath $logFile -Value "Log ended: $(Get-Date)"
exit
