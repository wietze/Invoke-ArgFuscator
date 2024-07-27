using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"

class UrlTransformer : Modifier {
    [float]$Probability;
    [boolean]$LeaveOutProtocol;
    [boolean]$LeaveOutDoubleSlashes;
    [boolean]$SubstituteSlashes;
    [boolean]$IpToHex;
    [boolean]$PathTraversal;

    UrlTransformer([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [float]$Probability, [boolean]$LeaveOutProtocol, [boolean]$LeaveOutDoubleSlashes, [boolean]$SubstituteSlashes, [boolean]$IpToHex, [boolean]$PathTraversal) : base($InputCommandTokens, $AppliesTo, $Probability) {
        $this.LeaveOutProtocol = $LeaveOutProtocol;
        $this.SubstituteSlashes = $SubstituteSlashes;
        $this.IpToHex = $IpToHex;
        $this.PathTraversal = $PathTraversal;
    }

    [void]GenerateOutput() {
        foreach ($Token in $this.InputCommandTokens) {
            $NewTokenContent = $Token.ToString();

            if ($this.AppliesTo.Contains($Token.Type)) {
                # Leave out protocol
                if ($this.LeaveOutProtocol -and [Modifier]::CoinFlip($this.Probability)) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "\w+:\/\/", "://");
                }

                # Path Traversal
                if ($this.PathTraversal) {
                    [int]$i = 0;
                    do {
                        $NewTokenContent = [regex]::replace($NewTokenContent, "([^/])([/])([^/])", {
                                $slash = $args[0].groups[2].value;
                                if ([Modifier]::CoinFlip($this.Probability)) {
                                    $subpath = $slash + [Modifier]::ChooseRandom([Modifier]::Keywords) + $slash + ".." + $slash;
                                    return $args[0].groups[1].value + $subpath + $args[0].groups[3].value;
                                }
                                return $args[0].groups[0].value;
                            });
                        $i++;
                    } while ([Modifier]::CoinFlip($this.Probability * [Math]::Pow(0.9, $i)));
                }

                # Change double slashes
                if ($this.LeaveOutDoubleSlashes -and [Modifier]::CoinFlip($this.Probability)) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "\:\/\/", ":/");
                }

                # Substitute slashes
                if ($this.SubstituteSlashes) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "\/+", {
                            if ([Modifier]::CoinFlip($this.Probability)) {
                                return "\" * $args[0].value.length;
                            }
                            return $args[0].value;
                        });
                }

                # IP Transform
                if ($this.IpToHex -and [Modifier]::CoinFlip($this.Probability)) {
                    $NewTokenContent = [regex]::replace($NewTokenContent, "(?:[0-9]{1,3}\.){3}[0-9]{1,3}", {
                            $ints = $args[0].value.split('.');
                            [array]::reverse($ints);
                            [int]$decimal = 0;
                            $ints | ForEach-Object { $i = 0 } { $decimal += ([int]$_ * [Math]::Pow(256, $i++)) };

                            if ([Modifier]::CoinFlip(0.5)) {
                                return $decimal;
                            }
                            else {
                                return '0x{0:x}' -f $decimal;
                            }
                        })
                }
                $Token.TokenContent = $NewTokenContent;
            }
        }
    }
}
