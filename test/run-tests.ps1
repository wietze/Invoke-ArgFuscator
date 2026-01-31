Import-Module -Force ./Invoke-ArgFuscator.psm1

$count = 100
if ($args.count -lt 1) {
    Write-Error "No path to JSONL file provided."
    exit
}

$testIndex = 0
$contents = Get-Content $args[0]
$contents | ForEach-Object {
    $testIndex += 1

    # Load JSON configuration line
    $obj = $_ | ConvertFrom-Json

    # Initialise variables
    $firstObservedStdout = $null

    # Run Invoke-ArgFuscator and iterate over output
    Invoke-ArgFuscator -InputFile $obj.path -Profile $obj.profileID -n $count | ForEach-Object {
        # Sanitise command
        $commandToRun = (($_ -replace '\s+', ' ').trim() -replace "`0", "")
        $currentObservedStdout = $null

        # If preCommand is defined, run it
        if ($obj.preCommand -ne $null){
            bash -c "$($obj.preCommand)"
        }

        # Prepare ProcessStartInfo block
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.RedirectStandardOutput = $true
        $psi.UseShellExecute = $false
        $psi.FileName = "/bin/bash"
        $psi.ArgumentList.Add("-c")
        # Get wrapper command, if needed
        $_command = if($obj.wrapperCommand -ne $null){ "$($obj.wrapperCommand -replace '\$COMMAND\b', $commandToRun) 2>&1" } else { "$commandToRun 2>&1" }
        $psi.ArgumentList.Add($_command)

        # Run generated command
        $p = [System.Diagnostics.Process]::Start($psi)
        if ($p.WaitForExit(10000)) {
            # Command exited, get stdout
            $currentObservedStdout = $p.StandardOutput.ReadToEnd()
        } else {
            # Command timed out, throw error
            $currentObservedStdout = ""
            $p.kill()
            Write-Host -ForegroundColor Red "ERROR: Command execution terminated - $commandToRun"
            return
        }


        if ($firstObservedStdout -eq $null) {
            # If this is the first run, make this the "expected output"
            $firstObservedStdout = $currentObservedStdout
            Write-Host -ForegroundColor Yellow "> Executed: ``$commandToRun``"
            Write-Host -ForegroundColor yellow "> Expected stdout:"
            Write-Host $firstObservedStdout
            Write-Host -ForegroundColor yellow "> Continue"
        } else {
            # If this is not the first run, compare the observed output with the expected output
            if($obj.outputCompare -eq $null -or $obj.outputCompare -eq "full"){
                if ($firstObservedStdout -ne $currentObservedStdout) {
                    Write-Host -ForegroundColor Red "ERROR: unexpected output for $_ ($($currentObservedStdout.length) vs $($firstObservedStdout.length))";
                    Write-Host -ForegroundColor Blue $currentObservedStdout;
                    return
                }
            } elseif($obj.outputCompare -eq "length"){
                if ($firstObservedStdout.length -ne $currentObservedStdout.length) {
                    Write-Host -ForegroundColor Red "ERROR: unexpected output length for $_ ($($currentObservedStdout.length) vs $($firstObservedStdout.length))";
                    Write-Host -ForegroundColor Blue $currentObservedStdout;
                    return
                }
            } elseif($obj.outputCompare -eq "exitcode"){
                # Skip, we'll do this anyway
            } else {
                Write-Host -ForegroundColor red "ERROR: Unexpected outputCompare option $($obj.outputCompare)"
                return
            }
        }

        $expectedStatusCode = if($obj.expectedStatusCode -ne $null){ $obj.expectedStatusCode } else { 0 }
        if ($p.ExitCode -ne $expectedStatusCode) {
            Write-Host -ForegroundColor red "ERROR: ($($p.ExitCode) != $expectedStatusCode)`n$_`n$currentObservedStdout";
            return
        }

        # If postCommand is defined, run it
        if ($obj.postCommand -ne $null){
            bash -c "$($obj.postCommand)"
        }

        $commandToRun
    } | ForEach-Object { $received = 0 } { $received += 1; [int]$percentComplete = ($received / $count) * 100; Write-Progress -Activity "Invoke-Argfuscator test for $( Split-Path $obj.path -leaf) ($testIndex/$($contents.Length))" -Status "$PercentComplete% complete" -PercentComplete $percentComplete; Write-Host -ForegroundColor green -nonewline "SUCCESS "; Write-Host $_ }
}
