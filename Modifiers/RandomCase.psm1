using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class RandomCase : Modifier {
    [float]$Probability;

    RandomCase([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
    }

    [void]GenerateOutput(){
        foreach($Token in $this.InputCommandTokens){
            $NewTokenContent = [System.Collections.ArrayList]@();
            foreach($Char in $Token.TokenContent){
                if(!$this.ExcludedTypes.Contains($Token.Type)){
                    if ([Modifier]::CoinFlip($this.Probability)) {
                        $NewTokenContent.Add([char]($Char.ToString().ToUpper() -eq $Char.ToString() ? $char.ToString().ToUpper() : $char.ToString().ToLower()));
                    } else {
                        $NewTokenContent.Add($char);
                    }
                    $Token.TokenContent = $NewTokenContent;
                }
            }
        }
    }
}
