using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"
using module "..\Types\Argument.psm1"

class Shorthands : Modifier {
    [float]$Probability;
    [boolean]$CaseSensitive;
    [System.Collections.Hashtable]$Substitutions;

    Shorthands([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [Argument[]]$Arguments, [float]$Probability, [bool]$CaseSensitive) : base($InputCommandTokens, $AppliesTo, $Arguments, $Probability) {
        $this.CaseSensitive = $CaseSensitive;
        $this.Substitutions = @{}`

        # Step 1: Normalize all arguments in one loop
        $Commands = @()
        foreach ($argus in $Arguments) {
            foreach($argo in $argus.Arguments) {
                $normalized = $this.NormaliseArgument($argo, $true)
                if ($null -ne $normalized) {
                    $Commands += $normalized
                }
            }
        }

        # Collect all possible abbreviations for all commands
        $allAbbreviations = @{}
        foreach ($cmd in $Commands) {
            $abbrevs = @()

            # If a suffix is present, temporarily remove it
            $suffix = ""
            if ([Modifier]::ValueChars -contains $cmd[-1]) {
                $suffix = $cmd[-1]
                $cmd = $cmd.Substring(0, $cmd.Length - $suffix.Length)
            }

            for ($i = $cmd.Length - 1; $i -ge 2; $i--) {
                $abbrev = $cmd.Substring(0, $i) + $suffix
                $abbrevs += $abbrev
                if ($allAbbreviations.ContainsKey($abbrev)) {
                    $allAbbreviations[$abbrev] += $cmd
                } else {
                    $allAbbreviations[$abbrev] = @($cmd)
                }
            }
        }

        # For each command, only keep abbreviations that are unique to it
        foreach ($cmd in $Commands) {
            $uniqueAbbreviations = @()

            # If a suffix is present, temporarily remove it
            $suffix = ""
            if ([Modifier]::ValueChars -contains $cmd[-1]) {
                $suffix = $cmd[-1]
                $cmd = $cmd.Substring(0, $cmd.Length - $suffix.Length)
            }

            for ($i = $cmd.Length - 1; $i -ge 2; $i--) {
                $abbrev = $cmd.Substring(0, $i) + $suffix
                if ($allAbbreviations[$abbrev].Count -eq 1) {
                    $uniqueAbbreviations += $abbrev
                }
            }
            if($uniqueAbbreviations.Length -gt 0){
                $this.Substitutions[$cmd + $suffix] = $uniqueAbbreviations
            }
        }

        # # Step 2: Precompute all prefixes in a dictionary for fast lookup
        # $prefixDict = @{}
        # foreach ($cmd in $Commands) {
        #     for ($j = 1; $j -le $cmd.Length; $j++) {
        #         $prefix = $cmd.Substring(0, $j)
        #         $prefixDict[$prefix] = $true
        #     }
        # }

        # # Step 3: Generate substitutions
        # foreach ($command in $Commands) {
        #     if ($command.Length -le 1) { continue }

        #

        #     for ($i = 1; $i -lt $command.Length; $i++) {
        #         $command_shortened = $command.Substring(0, $i)

        #         # Check if any other command shares this prefix
        #         $prefixExists = $false
        #         foreach ($otherCmd in $Commands) {
        #             if ($otherCmd -ne $command -and $i -lt $otherCmd.Length -and $otherCmd.Substring(0, $i) -eq $command_shortened) {
        #                 $prefixExists = $true
        #                 break
        #             }
        #         }

        #         if (-not $prefixExists) {
        #             $options = @()
        #             for ($k = $i; $k -le $command.Length - $suffix.Length; $k++) {
        #                 $options += $command.Substring(0, $k) + $suffix
        #             }

        #             $this.Substitutions[$command] = $options
        #             foreach ($opt in $options) {
        #                 $this.Substitutions[$opt] = $options
        #             }
        #             break
        #         }
        #     }
        # }
    }

    [string]NormaliseArgument([string]$argument, [bool]$strip_option_char) {
        $result = $argument

        if ($strip_option_char -and [Modifier]::CommonOptionChars -contains $argument[0]) {
            $result = $result.Substring(1)
        }

        if (-not $this.CaseSensitive) {
            $result = $result.ToLower()
        }

        return $result
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            if ($this.AppliesTo.Contains($Token.Type) -and [Modifier]::CoinFlip($this.Probability)) {
                $NewTokenContent = $this.NormaliseArgument($Token.ToString(), $true)
                $suffix = if([Modifier]::ValueChars -contains $NewTokenContent[-1]){ $NewTokenContent[-1] } else { "" }
                if ($this.Substitutions.ContainsKey($NewTokenContent.Substring(0, $NewTokenContent.length - $suffix.length))) {
                    $OriginalToken = $this.NormaliseArgument($Token.ToString(), $false)
                    $Token.TokenContent = $OriginalToken.Replace($NewTokenContent.Substring(0, $NewTokenContent.length - $suffix.length), [Modifier]::ChooseRandom($this.Substitutions[$NewTokenContent.Substring(0, $NewTokenContent.length - $suffix.length)])).ToCharArray()
                }
            }
        }
    }
}
