using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class OptionCharSubstitution : Modifier {
    [char]$ProvidedOptionChar;
    [char[]]$OutputOptionChars;

    OptionCharSubstitution([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [bool]$Probability, [char]$ProvidedOptionChar, [char[]]$OutputOptionChars) : base($InputCommandTokens, $ExcludedTypes, $Probability) {
        $this.ProvidedOptionChar = $ProvidedOptionChar;
        $this.OutputOptionChars = $OutputOptionChars;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            if (!$this.ExcludedTypes.Contains($Token.Type) -and $Token.TokenContent[0] -eq $this.ProvidedOptionChar) {
                $Token.TokenContent[0] = [Modifier]::ChooseRandom($this.OutputOptionChars);
            }
        }
    }
}
