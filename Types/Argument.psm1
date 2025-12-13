class Argument {
    [string[]]$Arguments;
    [int]$ValueCount;
    [boolean]$Redundant;

    Argument([string[]]$Arguments, [int]$ValueCount, [boolean]$Redundant) {
        $this.Arguments = $Arguments;
        $this.ValueCount = if ($null -ne $ValueCount) { $ValueCount } else { 0 };
        $this.Redundant = if($null -ne $Redundant) { $Redundant } else { $false };
    }

    static [Argument]GetArgumentDetails([System.Collections.ArrayList]$Arguments, [char[]]$TokenContent){
        if ($null -ne $Arguments) {
            $ParsedArg = $Arguments.Where({ $_.Arguments.Where({(-not (Compare-Object -CaseSensitive (-join $TokenContent) $_))}) });

            if (($null -ne $ParsedArg) -and ($ParsedArg.Count -gt 0)) {
                return $ParsedArg[0]
            }
        }

        return $null;
    }
}
