using module ".\Token.psm1"
class Modifier {
    [Token[]]$InputCommandTokens;
    [string[]]$ExcludedTypes = $("disabled");
    [bool]$Probability;
    static [char]$SeparationChar = ' ';
    static [char[]]$QuoteChars = @('"', '''');
    static [string[]]$ValueChars = @("=", ":");
    static [string[]]$CommonOptionChars = @("/", "-");
    static [string[]]$Keywords = @("debug", "system32", "compile", "winsxs", "temp", "update")

    Modifier([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability) {
        $this.InputCommandTokens = $InputCommandTokens;
        $this.ExcludedTypes += $ExcludedTypes;
        $this.Probability = $Probability;
    }

    static [boolean]CoinFlip([float]$Probability) {
        return (Get-Random -Minimum 0.0 -Maximum 1.0) -gt (1 - $Probability);
    }

    static [object]ChooseRandom([object[]]$Items) {
        return Get-Random -InputObject $Items;
    }

    static [System.Collections.ArrayList]Tokenise([string]$InputCommand) {
        $InQuote = $null;
        $Tokens = [System.Collections.ArrayList]@(); #[Token[]]
        $TokenContent = [System.Collections.ArrayList]@(); #[char[]]

        for ($i = 0; $i -lt $InputCommand.Length; $i++) {
            [char]$Char = $InputCommand[$i];
            if ($null -eq $InQuote -and $Char -eq [Modifier]::SeparationChar) {
                if ($TokenContent.Length -gt 0) {
                    $Tokens.Add([Token]::new($TokenContent));
                }
                $TokenContent = [System.Collections.ArrayList]@();
            }
            else {
                if ($null -ne $InQuote -and $InQuote -eq $Char) {
                    $InQuote = $null;
                }
                elseif ($null -eq $InQuote -and [Modifier]::QuoteChars.Contains($Char)) {
                    $InQuote = $Char;
                }

                $TokenContent.Add($Char);
            }
        }
        if ($TokenContent.Length -gt 0) {
            $Tokens.Add([Token]::new($TokenContent));
        }

        return $Tokens;
    }

    [void]GenerateOutput() {
        Write-Host("NOT IMPLEMENTED");
    }
}
