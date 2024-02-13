using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class QuoteInsertion : Modifier {
    [float]$Probability;
    static [char]$QuoteChar = '"';

    QuoteInsertion([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
    }

    [void]GenerateOutput(){
        foreach($Token in $this.InputCommandTokens){
            $NewTokenContent = [System.Collections.ArrayList]@();
            $i = 0;
            foreach($Char in $Token.TokenContent){
                $NewTokenContent.Add($Char);
                if(!$this.ExcludedTypes.Contains($Token.Type) -and [Modifier]::CoinFlip($this.Probability)){
                    do {
                        $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
                        $i++;
                    } while ([Modifier]::CoinFlip($this.Probability * [Math]::Pow(0.9, $i)));
                }
            }
            if (($i % 2) -ne 0){
                $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
            }

            $Token.TokenContent = $NewTokenContent;
        }
    }
}
