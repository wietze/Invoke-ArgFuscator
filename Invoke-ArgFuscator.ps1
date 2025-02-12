﻿Import-Module ./Invoke-ArgFuscator.psm1

$n_default = 1
if ($args.Length -eq 0) {
    Write-Host "░█░█▄░█░█▒█░▄▀▄░█▄▀▒██▀░▒░" -NoNewline
    Write-Host " ▄▀▄▒█▀▄░▄▀▒▒" -NoNewline -f Blue
    Write-Host "█▀░█▒█░▄▀▀░▄▀▀▒▄▀▄░▀█▀░▄▀▄▒█▀▄░" -f DarkGray
    Write-Host "░█░█▒▀█░▀▄▀░▀▄▀░█▒█░█▄▄░▀▀░" -NoNewline
    Write-Host "█▀█░█▀▄░▀▄█░" -NoNewline -f Blue
    Write-Host "█▀░▀▄█▒▄██░▀▄▄░█▀█░▒█▒░▀▄▀░█▀▄░" -f DarkGray
    Write-Host "By " -NoNewline
    Write-Host "@Wietze" -f Blue -NoNewline
    Write-Host ", (c) 2024-2025`n"

    $InputFile = Read-Host "Path to configuration file"
    if (!($n = Read-Host "Number of commands to generate [default=$n_default]")) { $n = $n_default }
    $Args = @{ InputFile = $InputFile; n = $n };
}

Invoke-ArgFuscator @Args
