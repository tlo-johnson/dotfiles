# windows-terminal.ps1 — upsert the Catppuccin Mocha color scheme into Windows Terminal settings.
# Called by setup.ps1; can also be run standalone to re-apply after a WT update.

$wtDir      = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$wtSettings = "$wtDir\settings.json"

$catppuccinMocha = [PSCustomObject]@{
    name                = "Catppuccin Mocha"
    background          = "#1E1E2E"; foreground          = "#CDD6F4"
    cursorColor         = "#F5E0DC"; selectionBackground = "#585B70"
    black               = "#45475A"; red                 = "#F38BA8"
    green               = "#A6E3A1"; yellow              = "#F9E2AF"
    blue                = "#89B4FA"; purple              = "#F5C2E7"
    cyan                = "#94E2D5"; white               = "#BAC2DE"
    brightBlack         = "#585B70"; brightRed           = "#F38BA8"
    brightGreen         = "#A6E3A1"; brightYellow        = "#F9E2AF"
    brightBlue          = "#89B4FA"; brightPurple        = "#F5C2E7"
    brightCyan          = "#94E2D5"; brightWhite         = "#A6ADC8"
}

if (-not (Test-Path $wtDir)) {
    Write-Host "  [skip] Windows Terminal not found at expected path — re-run after installing"
} elseif (Test-Path $wtSettings) {
    # Merge into existing settings: upsert color scheme only.
    $s = Get-Content $wtSettings -Raw | ConvertFrom-Json

    if (-not $s.schemes) { $s | Add-Member -NotePropertyName schemes -NotePropertyValue @() }
    $s.schemes = @($s.schemes | Where-Object { $_.name -ne "Catppuccin Mocha" }) + $catppuccinMocha

    $s | ConvertTo-Json -Depth 10 | Set-Content $wtSettings -Encoding UTF8
    Write-Host "  Updated Windows Terminal color scheme in $wtSettings"
} else {
    # No settings file yet — create a minimal one.
    [PSCustomObject]@{
        '$schema' = "https://aka.ms/terminal-profiles-schema"
        schemes   = @($catppuccinMocha)
    } | ConvertTo-Json -Depth 10 | Set-Content $wtSettings -Encoding UTF8
    Write-Host "  Created Windows Terminal settings at $wtSettings"
}
