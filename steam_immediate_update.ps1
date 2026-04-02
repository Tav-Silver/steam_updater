# List all your Steam library steamapps folders here
$LibraryPaths = @(
    "C:\Program Files (x86)\Steam\steamapps",
    "D:\SteamLibrary\steamapps",
    "E:\SteamLibrary\steamapps",
    "F:\SteamLibrary\steamapps",
    "G:\SteamLibrary\steamapps",
    "H:\SteamLibrary\steamapps"
)

$findString = '("AutoUpdateBehavior"\s+)"\d+"'
$replaceString = '$1"2"'

# Counter for updated games
$updatedCount = 0

Write-Host "
___________           /\        _________ __                         
\__    ___/____ ___  _\/_____  /   _____//  |_  ____ _____    _____  
  |    |  \__  \\  \/ /  ___/  \_____  \\   __\/ __ \\__  \  /     \ 
  |    |   / __ \\   /\___ \   /        \|  | \  ___/ / __ \|  Y Y  \
  |____|  (____  /\_//____  > /_______  /|__|  \___  >____  /__|_|  /
               \/         \/          \/           \/     \/      \/ 
 ____ ___             ___       __    			                     
|    |   \______   __| _/____ _/  |_  ___________                    
|    |   /\____ \ / __ |\__  \\   __\/ __ \_  __ \                   
|    |  / |  |_) v /_/ | / __ \|  | \  ___/|  | \/                   
|______/  |   __/\____ |(____  /__|  \___> |__|                v1.0
          |__|        \/     \/          \/       
" -ForegroundColor Yellow

Write-Host "Altering Steam to download game updates immediately." -ForegroundColor White
Write-Host "Reboot Steam for changes to take effect." -ForegroundColor White
Write-Host ""

foreach ($path in $LibraryPaths) {
    if (Test-Path $path) {
        Write-Host "Checking library: $path" -ForegroundColor Green

        # Temporary list for updated games in this library
        $libraryUpdatedGames = @()

        Get-ChildItem -Path $path -Filter 'appmanifest*.acf' -File | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8

        # Extract game name
        if ($content -match '"name"\s+"([^"]+)"') {
        $name = $matches[1]

        } else {
        $name = "Unknown"
    }

        # Match current AutoUpdateBehavior
        if ($content -match '"AutoUpdateBehavior"\s+"(\d+)"') {
        $currentValue = [int]$matches[1]

        if ($currentValue -ne 2) {
            $newContent = $content -replace '"AutoUpdateBehavior"\s+"\d+"', '"AutoUpdateBehavior"    "2"'
            Set-Content $_.FullName $newContent -Encoding UTF8
            $libraryUpdatedGames += $name
            $updatedCount++
        }
    }
}

        # Print all updated games for this library together
        if ($libraryUpdatedGames.Count -gt 0) {
            Write-Host ""
            foreach ($game in $libraryUpdatedGames) {
                Write-Host "   Updated: $game" -ForegroundColor Cyan
            }
            Write-Host ""
        }
    }
    else {
        Write-Host "Path not found: $path" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Games updated: $updatedCount" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press ENTER to close"