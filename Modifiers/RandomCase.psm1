using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"
using module "..\Types\Argument.psm1"

class RandomCase : Modifier {
    [float]$Probability;

    RandomCase([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [Argument[]]$Arguments, [float]$Probability) : base($InputCommandTokens, $AppliesTo, $Arguments, $Probability) {
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            if ($this.AppliesTo.Contains($Token.Type)) {
                $NewTokenContent = [System.Collections.ArrayList]@();
                foreach ($Char in $Token.TokenContent) {
                    if ([Modifier]::CoinFlip($this.Probability)) {
                        $NewTokenContent.Add([char](($char.ToString().ToUpper(), $char.ToString().ToLower())[!($Char.ToString().ToUpper() -eq $Char.ToString())]));
                    }
                    else {
                        $NewTokenContent.Add($char);
                    }
                    $Token.TokenContent = $NewTokenContent;
                }
            }
        }
    }
}
