using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class Shorthands : Modifier {
    [float]$Probability;
    [boolean]$CaseSensitive;
    [System.Collections.HashTable]$Substitutions; #[string, string[]]
    static [char]$Separator = ',';

    Shorthands([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability, [string]$ShorthandCommands, [bool]$CaseSensitive) : base($InputCommandTokens, $ExcludedTypes, $Probability) {
        $this.CaseSensitive = $CaseSensitive;
        $this.Substitutions = @{};
        $Commands = $ShorthandCommands.split([Shorthands]::Separator) | ForEach-Object { $this.NormaliseArgument($_, $True) }

        $Commands | Where-Object { $null -ne $_ } | Foreach-Object {
            $command = $_
            if ($command.length -le 1) { return; }
            $suffix = [Modifier]::ValueChars -contains $command[-1] ? $command[-1] : "";

            $command_other_s = [System.Collections.Generic.HashSet[string]]$Commands;
            $command_other_s.Remove($command);

            for ($i = 1; $i -lt $command.length; $i++) {
                $command_shortened = $command.substring(0, $i);
                if (!(($command_other_s | ForEach-Object { ($i -lt $_.length) -and ($_.substring(0, $i) -eq $command_shortened) }) -contains $true)) {
                    $options = ($i..($command.length - $suffix.length)) | ForEach-Object { $command.substring(0, $_) + $suffix };
                    $this.Substitutions.Add($command, $options);
                    $options | ForEach-Object { $this.Substitutions[$_] = $options }
                    break;
                }
            }

        }
    }

    [string]NormaliseArgument([string]$argument, [bool]$strip_option_char) {
        $result = $argument;
        if ($strip_option_char -and (([Modifier]::CommonOptionChars | ForEach-Object { $argument.StartsWith($_) }) -contains $true)) {
            $result = $result.Substring(1);
        }

        if (!$this.CaseSensitive) {
            $result = $result.ToLower();
        }

        return $result;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            if (!$this.ExcludedTypes.Contains($Token.Type) -and [Modifier]::CoinFlip($this.Probability)) {
                $NewTokenContent = $this.NormaliseArgument($Token.ToString(), $True);
                if ($this.Substitutions.ContainsKey($NewTokenContent)) {
                    $OriginalToken = $this.NormaliseArgument($Token.ToString(), $False);
                    $Token.TokenContent = $OriginalToken.Replace($NewTokenContent, [Modifier]::ChooseRandom($this.Substitutions[$NewTokenContent])).ToCharArray();
                }
            }
        }
    }
}
