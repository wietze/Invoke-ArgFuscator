using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class FilePathTransformer : Modifier {
    [float]$Probability;
    [boolean]$PathTraversal;
    [boolean]$SubstituteSlashes;
    [boolean]$ExtraSlashes;
    $keywords = @("debug", "system32", "compile", "winsxs", "temp", "update")

    FilePathTransformer([Token[]]$InputCommandTokens, [string[]]$ExcludedTypes, [float]$Probability, [boolean]$PathTraversal, [boolean]$SubstituteSlashes, [boolean]$ExtraSlashes) : base($InputCommandTokens, $ExcludedTypes) {
        $this.Probability = $Probability;
        $this.PathTraversal = $PathTraversal;
        $this.SubstituteSlashes = $SubstituteSlashes;
        $this.ExtraSlashes = $ExtraSlashes;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = $Token.ToString();

            if (!$this.ExcludedTypes.Contains($Token.Type)) {
                # Path Traversal
                if ($this.PathTraversal) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "([^\\/])([\\/])([^\\/])", {
                            $slash = $args[0].groups[2].value;
                            if ([Modifier]::CoinFlip($this.Probability)) {
                                $subpath = $slash + [Modifier]::ChooseRandom($this.Keywords) + $slash + ".." + $slash;
                                return $args[0].groups[1].value + $subpath + $args[0].groups[3].value;
                            }
                            return $args[0].groups[0].value;
                        });
                }

                # Substitute slashes
                if ($this.SubstituteSlashes) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "[/\\]", {
                            if ([Modifier]::CoinFlip($this.Probability)) {
                                if ($args[0].value -eq "/") {
                                    return "\\"
                                }
                                return "/"
                            }
                            return $args[0].value;
                        });
                }

                # Extra slashes
                if ($this.ExtraSlashes) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "([^\\/])([\\/])([^\\/])", {
                            $slash = $args[0].groups[2].value;
                            if ([Modifier]::CoinFlip($this.Probability)) {
                                $extra_slashes = $slash * [Modifier]::ChooseRandom($(2, 3, 4));
                                return $args[0].groups[1].value + $extra_slashes + $args[0].groups[3].value;
                            }
                            return $args[0].groups[0].value;
                        });
                }
                $Token.TokenContent = $NewTokenContent;
            }
        }
    }
}
