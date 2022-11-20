using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class CharacterInsertion : Modifier {
    [float]$Probability;
    [char[]]$Characters;

    CharacterInsertion([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability, [string[]]$Characters) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
        $this.Characters = $Characters;
    }

    [void]GenerateOutput(){
        foreach($Token in $this.InputCommandTokens){
            $NewTokenContent = [System.Collections.ArrayList]@();
            foreach($Char in $Token.TokenContent){
                $NewTokenContent.Add($Char);
                $i = 0;
                if(!$this.ExcludedTypes.Contains($Token.Type) -and [Modifier]::CoinFlip($this.Probability)){
                    do {
                        $chosen = [Modifier]::ChooseRandom($this.Characters)
                        $NewTokenContent.Add($chosen);
                        $i++;
                    } while ([Modifier]::CoinFlip($this.Probability * [Math]::Pow(0.9, $i)));
                }
            }

            $Token.TokenContent = $NewTokenContent;
        }
    }
}
