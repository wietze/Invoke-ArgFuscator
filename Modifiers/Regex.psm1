using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

# 'Regex' is taken, hence 'RegularExpression'
class RegularExpression : Modifier {
    [float]$Probability;
    [string]$RegexMatch;
    [string]$RegexReplace;

    RegularExpression([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability, [string]$RegexMatch, [string]$RegexReplace, [boolean]$CaseSensitive) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
        $this.RegexMatch = $RegexMatch;
        if(!$CaseSensitive){
            $this.RegexMatch = "(?i)"+ $this.RegexMatch;
        }
        $this.RegexReplace = $RegexReplace;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = $Token.ToString();

            if (!$this.ExcludedTypes.Contains($Token.Type) -and [Modifier]::CoinFlip($this.Probability)) {
                $this.RegexReplace = [regex]::replace($this.RegexReplace, "\`$(\d+)\[(\d+):(\d+(?:-x?(?:\d+)?)?)\]", {
                    [int]$rIndex = $args[0].groups[1].value
                    [int]$start = $args[0].groups[2].value
                    [string]$end = $args[0].groups[3].value
                    if($NewTokenContent -match $this.RegexMatch){
                        $match = $Matches[$rIndex]
                        if($end.IndexOf('-') -ge 0){
                            $ids = $end.split('-')
                            if($ids[1] -eq ''){$ids[1] = $match.length;}
                            [int]$end = Get-Random -Minimum ([int]($ids[0])) -Maximum ([int]($ids[1]));
                        }
                        return $match.substring($start, $end);
                    }
                    return $args[0].value;
                });

                $this.RegexMatch = $this.RegexMatch -replace "`$RANDOM",(-join((65..90) + (97..122)|Get-Random -Count (Get-Random -minimum 1 -Maximum 20)|ForEach-Object {[char]$_}))

                $NewTokenContent = [regex]::replace($NewTokenContent, $this.RegexMatch, $this.RegexReplace)
                $Token.TokenContent = $NewTokenContent;
            }
        }
    }
}
