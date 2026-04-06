# run-emulator.ps1
# Enhanced script for FlowPOS development

$sdkPath = if ($env:ANDROID_HOME) { $env:ANDROID_HOME } else { "$env:USERPROFILE\AppData\Local\Android\Sdk" }
$emulatorPath = Join-Path $sdkPath "emulator\emulator.exe"
$adbPath = Join-Path $sdkPath "platform-tools\adb.exe"

if (-not (Test-Path $emulatorPath)) {
    Write-Error "Emulator not found at $emulatorPath. Please check your ANDROID_HOME environment variable."
    exit 1
}

# --- SELF-HEALING PATH FOR FLUTTER ---
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    $potentialFlutterPaths = @("C:\tools\flutter\bin", "C:\src\flutter\bin", "$env:USERPROFILE\flutter\bin")
    foreach ($path in $potentialFlutterPaths) {
        if (Test-Path $path) {
            $env:Path += ";$path"
            Write-Host "Discovered Flutter at $path (Updated session PATH)" -ForegroundColor Gray
            break
        }
    }
}
# -------------------------------------

# 1. Get available AVDs
$avds = & $emulatorPath -list-avds
if (-not $avds) {
    Write-Error "No Android Virtual Devices (AVDs) found in your SDK."
    exit 1
}

# 2. Check for currently connected devices/emulators
$runningDevices = & $adbPath devices | Select-String -Pattern "	device$"
$useExisting = $false

if ($runningDevices) {
    Write-Host "`n[Connected Devices]" -ForegroundColor Cyan
    $runningDevices | ForEach-Object { Write-Host " - $($_.ToString().Replace('	device',''))" }
    
    $ans = Read-Host "Use currently connected device? (Y/n)"
    if ($ans -match "^$|^y" -or $ans -eq "Y") {
        $useExisting = $true
    }
}

$targetAvd = ""
if (-not $useExisting) {
    if ($avds.Count -eq 1) {
        $targetAvd = $avds[0]
    } else {
        Write-Host "`n[Available Emulators]" -ForegroundColor Cyan
        for ($i = 0; $i -lt $avds.Count; $i++) {
            Write-Host " [$($i + 1)] $($avds[$i])"
        }
        $choice = Read-Host "Select emulator to launch (1-$($avds.Count))"
        if ($choice -match '^\d+$' -and [int]$choice -le $avds.Count -and [int]$choice -gt 0) {
            $targetAvd = $avds[[int]$choice - 1]
        } else {
            Write-Error "Invalid selection."
            exit 1
        }
    }

    Write-Host "`nLaunching $targetAvd..." -ForegroundColor Green
    Start-Process -FilePath $emulatorPath -ArgumentList "-avd $targetAvd -netdelay none -netspeed full" -WindowStyle Hidden

    Write-Host "Waiting for boot..." -NoNewline
    $timeout = 90
    while ($timeout -gt 0) {
        $bootProp = & $adbPath shell getprop sys.boot_completed 2>$null
        if ($bootProp -eq "1") {
            Write-Host " [DONE]" -ForegroundColor Green
            break
        }
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 3
        $timeout -= 3
    }
}

Write-Host "`n----------------------------------------------------"
Write-Host "Building and Running (Development Flavor)..." -ForegroundColor Yellow
Write-Host "----------------------------------------------------"

# Note: Ensure 'flutter' is in your PATH. 
# If it fails, manually run: flutter run --flavor development
flutter run --flavor development
