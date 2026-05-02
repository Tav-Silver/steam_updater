$findString = '"AutoUpdateBehavior"\s+"\d+"'
$replaceString = '"AutoUpdateBehavior"    "2"'

$updatedCount = 0

Write-Host "
  ┌──────────────────────────┐
  │   TAV'S STEAM UPDATER    │
  └──────────────────── v1.1 ┘
" -ForegroundColor Yellow

Write-Host "A script to make Steam download game updates immediately." -ForegroundColor White
Write-Host "Steam won’t detect changes automatically." -ForegroundColor White
Write-Host "Restart Steam for changes to take effect." -ForegroundColor White

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
    $rawPaths += $m.Groups[1].Value -replace '\\\\','\'
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
    $results += [PSCustomObject]@{
        SteamLibraryPath  = $steamApps
        TotalAppmanifests = $appmanifests.Count
        UpdatedGamesCount = $libraryUpdatedGamesCount
    }
}

# -------------------------------
# 5. Output Table (Reordered & Centered)
# -------------------------------

$results | Sort-Object SteamLibraryPath | Format-Table `
    @{Label="Steam libraries found"; Expression={$_.SteamLibraryPath}; Width=40; Alignment="Left"},
    @{Label="Updated games";   Expression={$_.UpdatedGamesCount}; Width=15; Alignment="Center"},
    @{Label="Total games";    Expression={$_.TotalAppmanifests}; Width=15; Alignment="Center"} `
    -AutoSize:$false


Write-Host "Games updated: " -ForegroundColor White -NoNewline
Write-Host "$updatedCount" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press " -ForegroundColor White -NoNewline
Write-Host "ENTER" -ForegroundColor Green -NoNewline
Write-Host " to close: " -ForegroundColor White -NoNewline
[void][System.Console]::ReadLine()
