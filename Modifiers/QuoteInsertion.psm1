using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class QuoteInsertion : Modifier {
    [float]$Probability;
    static [char]$QuoteChar = '"';

    QuoteInsertion([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability) : base($InputCommandTokens, $ExcludedTypes, $Probability) {

    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = [System.Collections.ArrayList]@();
            $i = 0;
            $index = 0;
            if (!$this.ExcludedTypes.Contains($Token.Type)) {
                $Content = $Token.ToString();
                foreach ($Char in $Token.TokenContent) {
                    $NewTokenContent.Add($Char);
                    if ([Modifier]::CoinFlip($this.Probability) -and `
                            ( ( $Content[-1] -ne [QuoteInsertion]::QuoteChar ) `
                            -or ( ($index -gt 0) -and `
                            ($Char -match '^[a-zA-Z0-9]$') -and `
                            ($index -lt ($Content.Length - 2)) -and `
                            ($Content[$index+1] -match '^[a-zA-Z0-9]$')) `
                    )){
                        $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
                        $i++;
                    }
                    $index++;
                }

                # Check if there are unbalanced quotes
                if (($i % 2) -ne 0) {
                    if ($NewTokenContent[-1] -eq [QuoteInsertion]::QuoteChar) {
                        if ($content[-1] -eq [QuoteInsertion]::QuoteChar) {
                            # Original token ended with quote, find the penultimate one
                            $NewTokenContent.RemoveAt(($NewTokenContent[0..($NewTokenContent.Count - 2)] -join '').lastIndexOf([QuoteInsertion]::QuoteChar));
                        } else {
                            $NewTokenContent.RemoveAt($NewTokenContent.Count - 1);
                        }
                    }
                    else {
                        $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
                    }
                }


                # Edge case: Check if we added a quote after a value char
                if (($NewTokenContent[-1] -eq [QuoteInsertion]::QuoteChar) -and ([Modifier]::ValueChars.Contains($NewTokenContent[-2]))) {
                    $NewTokenContent.RemoveAt($NewTokenContent.Count - 1); # Remove the final quote (leaving it may cause issues)
                    $NewTokenContent.RemoveAt($NewTokenContent.lastIndexOf([QuoteInsertion]::QuoteChar)); # Also remove the right-most quote character to balance the number of quotes out again
                }

                $Token.TokenContent = $NewTokenContent;
            }
        }
    }
}
