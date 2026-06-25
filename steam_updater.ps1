$Host.UI.RawUI.WindowTitle = "Tav's Steam Updater"
$findString = '"AutoUpdateBehavior"\s+"\d+"'
$replaceString = '"AutoUpdateBehavior"    "2"'

$updatedCount = 0
$librarySizes = @{}

Write-Host @"
  ┌──────────────────────────┐
  │   TAV'S STEAM UPDATER    │
  └──────────────────── v1.2 ┘
"@ -ForegroundColor Yellow

Write-Host @"

A script to make Steam download game updates immediately.
Unfortunately Steam doesn't detect changes automatically.
Steam will restart if the script detects a change.

"@ -ForegroundColor White

# -------------------------------
# 1. Get Steam Path & Normalize
# -------------------------------

$steamReg = "HKCU:\Software\Valve\Steam"
$rawSteamPath = (Get-ItemProperty -Path $steamReg -ErrorAction SilentlyContinue).SteamPath

if (-not $rawSteamPath) {
    Write-Host "Steam not found in registry." -ForegroundColor Red
    exit
}

$steamPath = (Get-Item $rawSteamPath).FullName

# -------------------------------
# 2. Get libraryfolders.vdf
# -------------------------------

$libraryFile = Join-Path $steamPath "steamapps\libraryfolders.vdf"

if (-not (Test-Path $libraryFile)) {
    Write-Host "libraryfolders.vdf not found." -ForegroundColor Red
    exit
}

# -------------------------------
# 3. Parse and De-duplicate Libraries
# -------------------------------

$rawPaths = @()
$content = Get-Content $libraryFile -Raw

$vdfMatches = [regex]::Matches($content, '"path"\s*"([^"]+)"')

foreach ($m in $vdfMatches) {

    $libraryPath = $m.Groups[1].Value -replace '\\\\','\'
    $rawPaths += $libraryPath

    # Get size on disk from libraryfolders.vdf
    $libraryBlock = $content.Substring($m.Index)

    $appsBlock = [regex]::Match(
        $libraryBlock,
        '"apps"\s*\{([\s\S]*?)\}'
    )

    $sizeBytes = 0

    if ($appsBlock.Success) {

        $apps = [regex]::Matches(
            $appsBlock.Groups[1].Value,
            '"(\d+)"\s*"(\d+)"'
        )

        foreach ($app in $apps) {
            $sizeBytes += [int64]$app.Groups[2].Value
        }
    }

    $librarySizes[$libraryPath] = $sizeBytes
}

$rawPaths += $steamPath

$libraryPaths = $rawPaths | ForEach-Object {
    if (Test-Path $_) { (Get-Item $_).FullName.TrimEnd('\') }
} | Sort-Object -Unique

# -------------------------------
# 4. Process Libraries
# -------------------------------

$results = @()

foreach ($lib in $libraryPaths) {
    $steamApps = Join-Path $lib "steamapps"
    if (-not (Test-Path $steamApps)) { continue }

    $appmanifests = Get-ChildItem -Path $steamApps -Filter "appmanifest*.acf" -File -ErrorAction SilentlyContinue
    $libraryUpdatedGamesCount = 0

    foreach ($file in $appmanifests) {
        $fileContent = Get-Content $file.FullName -Raw -Encoding UTF8

        if ($fileContent -match '"AutoUpdateBehavior"\s+"(\d+)"') {
            if ($Matches[1] -ne "2") {
                $newContent = $fileContent -replace $findString, $replaceString
                Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
                $libraryUpdatedGamesCount++
                $updatedCount++
            }
        }
    }

    # Store results: This row shows the count for THIS specific drive
    
    $sizeBytes = $librarySizes[$lib]
    
    if ($sizeBytes -ge 1TB) {
        $sizeValue = [math]::Round($sizeBytes / 1TB, 2)
        $sizeUnit = "TB"
    }
    elseif ($sizeBytes -ge 1GB) {
        $sizeValue = [math]::Round($sizeBytes / 1GB, 0)
        $sizeUnit = "GB"
    }
    else {
        $sizeValue = [math]::Round($sizeBytes / 1MB, 0)
        $sizeUnit = "MB"
    }
    
    $results += [PSCustomObject]@{
        SteamLibraryPath  = $steamApps
        UpdatedGamesCount = $libraryUpdatedGamesCount
        TotalAppmanifests = $appmanifests.Count
        SizeOnDisk        = "$sizeValue $sizeUnit"
    }
}

# -------------------------------
# 5. Output Table (Reordered & Centered)
# -------------------------------

$results | Sort-Object SteamLibraryPath | Format-Table `
    @{Label="Steam libraries found"; Expression={$_.SteamLibraryPath}; Width=40; Alignment="Left"},
    @{Label="Games updated"; Expression={$_.UpdatedGamesCount}; Width=15; Alignment="Center"},
    @{Label="Games on disk"; Expression={$_.TotalAppmanifests}; Width=15; Alignment="Center"},
    @{Label="Size on disk"; Expression={ $_.SizeOnDisk.PadLeft(8).PadRight(10) }; Width=15; Alignment="Center"} `
    -AutoSize:$false


Write-Host "Games updated: " -ForegroundColor White -NoNewline
Write-Host "$updatedCount" -ForegroundColor Yellow
Write-Host ""

# ------------------------------------------
# Skip Steam restart if no changes were made
# ------------------------------------------

if ($updatedCount -eq 0) {

    Write-Host "Press " -ForegroundColor White -NoNewline
    Write-Host "ENTER" -ForegroundColor Green -NoNewline
    Write-Host " to close: " -ForegroundColor White -NoNewline

    [void][System.Console]::ReadLine()

    exit
}

# ------------------------------------------
# Spinner
# ------------------------------------------

$script:SpinPos = 0


function Show-Spinner {

    $spinner = @('/', '-', '\', '|')

    Write-Host -NoNewline "`r[$($spinner[$script:SpinPos])] Restarting Steam..."

    $script:SpinPos = ($script:SpinPos + 1) % $spinner.Count
}

function Wait-WithSpinner {

    param(
        [scriptblock]$Condition,
        [int]$TimeoutSeconds = 60
    )


    $elapsed = 0

    while (& $Condition -and ($elapsed -lt ($TimeoutSeconds * 1000))) {

        Show-Spinner

        Start-Sleep -Milliseconds 125

        $elapsed += 125
    }
}

# ------------------------------------------
# Locate Steam
# ------------------------------------------

$steamRegPaths = @(
    "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
    "HKLM:\SOFTWARE\Valve\Steam",
    "HKCU:\SOFTWARE\Valve\Steam",

    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 0",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 0"
)


$steamPath = $null


foreach ($regPath in $steamRegPaths) {

    if (-not (Test-Path $regPath)) {
        continue
    }


    try {

        $regData = Get-ItemProperty -Path $regPath -ErrorAction Stop


        $possiblePaths = @(
            $regData.InstallPath,
            $regData.InstallLocation
        ) | Where-Object { $_ }


        foreach ($installPath in $possiblePaths) {

            $candidate = Join-Path $installPath "Steam.exe"


            if (Test-Path $candidate) {

                $steamPath = $candidate
                break
            }
        }


        if ($steamPath) {
            break
        }

    }
    catch {}
}

# ------------------------------------------
# Fallback paths
# ------------------------------------------

if (-not $steamPath) {


    $commonPaths = @(
        "C:\Program Files (x86)\Steam\Steam.exe",
        "C:\Program Files\Steam\Steam.exe",
        "D:\Steam\Steam.exe",
        "E:\Steam\Steam.exe",
        "F:\Steam\Steam.exe",
        "G:\Steam\Steam.exe"
    )
    
    foreach ($path in $commonPaths) {

        if (Test-Path $path) {

            $steamPath = $path
            break
        }
    }
}

if (-not $steamPath) {

    Write-Host "`r[X] Steam installation not found." -ForegroundColor Red
    exit 1
}

try {

    $steamPath = (Resolve-Path $steamPath).Path

}
catch {}

# ------------------------------------------
# Stop Steam
# ------------------------------------------

$steamRunning = Get-Process -Name "steam" -ErrorAction SilentlyContinue

if ($steamRunning) {

    # Ask Steam to exit normally

    try {

        Start-Process `
            -FilePath $steamPath `
            -ArgumentList "-shutdown" `
            -WindowStyle Hidden

    }
    catch {}
    
    # Wait for graceful shutdown

    Wait-WithSpinner {

        Get-Process -Name "steam" -ErrorAction SilentlyContinue

    } 30
    
    # Try closing Steam windows

    $steamRunning = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    
    if ($steamRunning) {


        foreach ($proc in $steamRunning) {

            try {

                $proc.CloseMainWindow()

            }
            catch {}

        }
        
        Wait-WithSpinner {

            Get-Process -Name "steam" -ErrorAction SilentlyContinue

        } 10

    }
    
    # Last resort

    $steamRunning = Get-Process -Name "steam" -ErrorAction SilentlyContinue


    if ($steamRunning) {

        try {

            $steamRunning | Stop-Process -Force

        }
        catch {}

    }

}

# ------------------------------------------
# Start Steam
# ------------------------------------------

try {

    Start-Process -FilePath $steamPath

}
catch {

    Write-Host "`r[X] Failed to start Steam." -ForegroundColor Red
    exit 1
}

# ------------------------------------------
# Wait for Steam to return
# ------------------------------------------

Wait-WithSpinner {

    -not (Get-Process -Name "steam" -ErrorAction SilentlyContinue)

} 60

# ------------------------------------------
# Final 3 second confirmation spinner
# ------------------------------------------

$finishDelay = 6000
$elapsed = 0

while ($elapsed -lt $finishDelay) {

    Show-Spinner

    Start-Sleep -Milliseconds 125

    $elapsed += 125
}

Write-Host -NoNewline "`r[✓] Restarting Steam... " -ForegroundColor White
Write-Host "Done" -ForegroundColor Green
Write-Host ""
Write-Host "Press " -ForegroundColor White -NoNewline
Write-Host "ENTER" -ForegroundColor Green -NoNewline
Write-Host " to close: " -ForegroundColor White -NoNewline
[void][System.Console]::ReadLine()
