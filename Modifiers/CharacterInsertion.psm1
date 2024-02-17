using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class CharacterInsertion : Modifier {
    [float]$Probability;
    [char[]]$Characters;
    [int]$Offset;

    CharacterInsertion([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability, [string[]]$Characters, [int]$Offset) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
        $this.Characters = $Characters;
        $this.Offset = $Offset;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            if (!$this.ExcludedTypes.Contains($Token.Type)) {
                $NewTokenContent = [System.Collections.ArrayList]@();
                $Token.TokenContent | Select-Object -First $this.Offset | ForEach-Object { $NewTokenContent.Add($_) }

                foreach ($Char in ($Token.TokenContent | Select-Object -Skip $this.Offset)) {
                    $NewTokenContent.Add($Char);
                    $i = 0;
                    if ([Modifier]::CoinFlip($this.Probability)) {
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
}
