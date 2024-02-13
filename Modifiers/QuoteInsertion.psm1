using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class QuoteInsertion : Modifier {
    [float]$Probability;
    static [char]$QuoteChar = '"';

    QuoteInsertion([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = [System.Collections.ArrayList]@();
            $i = 0;
            if (!$this.ExcludedTypes.Contains($Token.Type)) {
                foreach ($Char in $Token.TokenContent) {
                    $NewTokenContent.Add($Char);
                    if ( [Modifier]::CoinFlip($this.Probability) -and !( $NewTokenContent[-1] -eq [QuoteInsertion]::QuoteChar)) {
                        #do {
                            $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
                            $i++;
                        ##} while ([Modifier]::CoinFlip($this.Probability * [Math]::Pow(0.9, $i)));
                    }
                }

                # Check if there are unbalanced quotes
                if (($i % 2) -ne 0) {
                    if($NewTokenContent[-1] -eq [QuoteInsertion]::QuoteChar){
                        $NewTokenContent.RemoveAt($NewTokenContent.Count - 1);
                    } else {
                        $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
                    }
                }


                # Edge case: Check if we added a quote after a value char
                if(($NewTokenContent[-1] -eq [QuoteInsertion]::QuoteChar) -and ([Modifier]::ValueChars.Contains($NewTokenContent[-2])))
                {
                    $NewTokenContent.RemoveAt($NewTokenContent.Count - 1); # Remove the final quote (leaving it may cause issues)
                    $NewTokenContent.RemoveAt($NewTokenContent.lastIndexOf([QuoteInsertion]::QuoteChar)); # Also remove the right-most quote character to balance the number of quotes out again
                }

                $Token.TokenContent = $NewTokenContent;
            }
        }
    }
}
