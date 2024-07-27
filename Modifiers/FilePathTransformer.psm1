using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class FilePathTransformer : Modifier {
    [float]$Probability;
    [boolean]$PathTraversal;
    [boolean]$SubstituteSlashes;
    [boolean]$ExtraSlashes;

    FilePathTransformer([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [float]$Probability, [boolean]$PathTraversal, [boolean]$SubstituteSlashes, [boolean]$ExtraSlashes) : base($InputCommandTokens, $AppliesTo, $Probability) {
        $this.PathTraversal = $PathTraversal;
        $this.SubstituteSlashes = $SubstituteSlashes;
        $this.ExtraSlashes = $ExtraSlashes;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = $Token.ToString();

            if ($this.AppliesTo.Contains($Token.Type)) {
                # Path Traversal
                if ($this.PathTraversal) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "([^\\/])([\\/])([^\\/])", {
                            $slash = $args[0].groups[2].value;
                            if ([Modifier]::CoinFlip($this.Probability)) {
                                $subpath = $slash + [Modifier]::ChooseRandom([Modifier]::Keywords) + $slash + ".." + $slash;
                                return $args[0].groups[1].value + $subpath + $args[0].groups[3].value;
                            }
                            return $args[0].groups[0].value;
                        });
                }

                # Substitute slashes
                if ($this.SubstituteSlashes) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "[/\\]+", {
                            if (($args[0].index -gt 0) -and [Modifier]::CoinFlip($this.Probability)) {
                                if ($args[0].value.StartsWith("/")) {
                                    return "\\" * $args[0].value.length
                                }
                                return "/" * $args[0].value.length
                            }
                            return $args[0].value;
                        });
                }

                # Extra slashes
                if ($this.ExtraSlashes) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "([^\\/])([\\/])([^\\/])", {
                            $slash = $args[0].groups[2].value;
                            if ([Modifier]::CoinFlip($this.Probability)) {
                                $extra_slashes = $slash * [Modifier]::ChooseRandom(@(2, 3, 4));
                                return $args[0].groups[1].value + $extra_slashes + $args[0].groups[3].value;
                            }
                            return $args[0].groups[0].value;
                        });
                }
            }
            $Token.TokenContent = $NewTokenContent;
        }
    }
}
