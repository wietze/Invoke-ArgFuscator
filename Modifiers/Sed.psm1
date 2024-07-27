using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"
using module "..\Types\Sed.psm1"

class Sed : Modifier {
    [float]$Probability;
    [SedStatement[]]$SedStatements;

    Sed([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [float]$Probability, [string]$SedStatements) : base($InputCommandTokens, $AppliesTo, $Probability) {
        $this.SedStatements = @();
        $SedStatements.Split("`n") | Where-Object { $null -ne $_ } | Foreach-Object {
            $this.SedStatements += (New-Object SedStatement -ArgumentList @($_))
        }
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = $Token.ToString();
            if ($this.AppliesTo.Contains($Token.Type)) {
                $SedMatches = $this.SedStatements | Where-Object { $_.StringIndex($Token.ToString()) -ge 0 }

                foreach ($Match in $SedMatches) {
                    $Instance = $match.StringIndex($NewTokenContent);
                    while ($Instance -ge 0) {
                        $Replacement = [Modifier]::ChooseRandom($Match.Replace);
                        if ([Modifier]::CoinFlip($this.Probability)) {
                            $NewTokenContent = $NewTokenContent.Substring(0, $instance) + $Replacement + $NewTokenContent.substring($instance + $match.Find.length);
                        }
                        $instance = $NewTokenContent.IndexOf($Match.Find, [Math]::Min($instance + $Replacement.Length, $NewTokenContent.Length));
                    }
                }
                $Token.TokenContent = $NewTokenContent.ToCharArray()
            }
        }
    }
}
