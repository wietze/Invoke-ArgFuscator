Import-Module ./Invoke-ArgFuscator.psm1

$n_default = 1
$profile_default = 0
if ($args.Length -eq 0) {
    Write-Host "░█░█▄░█░█▒█░▄▀▄░█▄▀▒██▀░▒░" -NoNewline
    Write-Host " ▄▀▄▒█▀▄░▄▀▒▒" -NoNewline -f Blue
    Write-Host "█▀░█▒█░▄▀▀░▄▀▀▒▄▀▄░▀█▀░▄▀▄▒█▀▄░" -f DarkGray
    Write-Host "░█░█▒▀█░▀▄▀░▀▄▀░█▒█░█▄▄░▀▀░" -NoNewline
    Write-Host "█▀█░█▀▄░▀▄█░" -NoNewline -f Blue
    Write-Host "█▀░▀▄█▒▄██░▀▄▄░█▀█░▒█▒░▀▄▀░█▀▄░" -f DarkGray
    Write-Host "By " -NoNewline
    Write-Host "@Wietze" -f Blue -NoNewline
    Write-Host ", (c) 2024-2026`n"

    $InputFile = Read-Host "> Path to configuration file"

    # Check if the file exists
    if (-not (Test-Path $InputFile)) {
        throw "Error: The file path '$InputFile' does not exist."
    }
    try {
        $fileContent = Get-Content -Path $InputFile
        $parsedJson = $fileContent | ConvertFrom-Json

        if($parsedJson.profiles.length -gt 1){
            Write-Host "Available profiles:"
            $i = 0;
            foreach($profile in $parsedJson.profiles){
                Write-Host " $($i): $($profile.platform)"
                $i++
            }
            if(-not ($profileID = Read-Host "> Profile ID [0-$($parsedJson.profiles.length - 1); default=0]")){
                $profileID = $profile_default
            }
        } else {
            $profileID = $profile_default
        }
    }
    catch {
        throw "Error: Failed to parse the content of the file '$InputFile' as JSON."
    }
    if (!($n = Read-Host "> Number of commands to generate [default=$n_default]")) { $n = $n_default }
    $args = @{ InputFile = $InputFile; Profile=$profileID; n = $n; Interactive = $true };
}

Invoke-ArgFuscator @args
