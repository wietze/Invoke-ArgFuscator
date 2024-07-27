using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class QuoteInsertion : Modifier {
    [float]$Probability;
    static [char]$QuoteChar = '"';

    QuoteInsertion([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [float]$Probability) : base($InputCommandTokens, $AppliesTo, $Probability) {

    }

    [string[]]AddQuotes([string[]]$Token){
        $NewTokenContent = [System.Collections.ArrayList]@();
        $index = 0;
        # if([Modifier]::CoinFlip($this.Probability)){
        #     $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
        # }
        foreach ($Char in $Token) {
            $nextChar = if ($index -lt ($Token.Length)) { $Token[$index+1] } else { "" }

            $NewTokenContent.Add($Char);


            if ([Modifier]::CoinFlip($this.Probability) `
                -and ($Char -match '^[a-zA-Z0-9\-\/]$') -and ($nextChar -match '^[a-zA-Z0-9\-\/]{0,1}$') `
                    ){
                        $NewTokenContent.Add([QuoteInsertion]::QuoteChar);
                    }
            $index++;

        }

        if(((($Token|where{$_-eq[QuoteInsertion]::QuoteChar})).length %2) -ne ((($NewTokenContent|where{$_-eq[QuoteInsertion]::QuoteChar})).length %2)){
            $j = -1;
            $NewTokenContent|foreach{$i=0}{if($_-eq[QuoteInsertion]::QuoteChar){$j=$i} $i++};

            $NewTokenContent.RemoveAt($j);
        }

        return $NewTokenContent;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = [System.Collections.ArrayList]@();
            $i = 0;
            $index = 0;
            if ($this.AppliesTo.Contains($Token.Type)) {
                $parts = $Token.ToString().split(" ");

                $Token.TokenContent = ($parts|foreach{$this.AddQuotes($_.ToCharArray()) -join ""}) -join " "
                ;
            }
        }
    }
}
