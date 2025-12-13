using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"
using module "..\Types\Argument.psm1"

class FilePathTransformer : Modifier {
    [float]$Probability;
    [boolean]$PathTraversal;
    [boolean]$SubstituteSlashes;
    [boolean]$ExtraSlashes;
    [boolean]$ValidFilePaths;
    static [string[]]$KeywordsNix = @("/usr/bin", "/usr/sbin", "/etc", "/var", "/var/log", "/var/lib", "/tmp", "/usr/libexec", "/usr/share", "/usr/local")

    FilePathTransformer([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [Argument[]]$Arguments, [float]$Probability, [boolean]$PathTraversal, [boolean]$SubstituteSlashes, [boolean]$ExtraSlashes, [boolean]$ValidFilePaths) : base($InputCommandTokens, $AppliesTo, $Arguments, $Probability) {
        $this.PathTraversal = $PathTraversal;
        $this.SubstituteSlashes = $SubstituteSlashes;
        $this.ExtraSlashes = $ExtraSlashes;
        $this.ValidFilePaths = $ValidFilePaths;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = $Token.ToString();

            if ($this.AppliesTo.Contains($Token.Type)) {
                # Path Traversal
                if ($this.PathTraversal) {
                    if ($this.ValidFilePaths) {
                        if ($NewTokenContent.StartsWith("/")) {
                            # Choose a random prefix from KeywordsNix
                            $prefix = [Modifier]::ChooseRandom([FilePathTransformer]::KeywordsNix)

                            # Count the number of "/" characters in the prefix
                            $depth = ($prefix.ToCharArray() | Where-Object { $_ -eq "/" }).Count

                            # Repeat "/.." depth times and prepend it with the prefix
                            $NewTokenContent = $prefix + ("/.." * $depth) + $NewTokenContent
                        }

                    }
                    else {
                        $NewTokenContent = [regex]::replace($NewTokenContent, "([^\\/])([\\/])([^\\/])", {
                                $slash = $args[0].groups[2].value;
                                if ([Modifier]::CoinFlip($this.Probability)) {
                                    $subpath = $slash + [Modifier]::ChooseRandom([Modifier]::Keywords) + $slash + ".." + $slash;
                                    return $args[0].groups[1].value + $subpath + $args[0].groups[3].value;
                                }
                                return $args[0].groups[0].value;
                            });
                    }
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
