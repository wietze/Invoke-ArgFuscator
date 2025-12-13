using module "..\Types\Modifier.psm1"
using module "..\Types\Token.psm1"
using module "..\Types\Argument.psm1"

class ReorderArgs : Modifier {
    [float]$Probability;

    [boolean]$CombineShortForm;
    [boolean]$RandomiseOrder;
    [boolean]$SwapLongShortForm;
    [boolean]$InsertRedundantShortforms;

    ReorderArgs([Token[]]$InputCommandTokens, [string[]]$AppliesTo, [Argument[]]$Arguments, [float]$Probability, [bool]$CombineShortForm, [bool]$RandomiseOrder, [bool]$SwapLongShortForm, [bool]$InsertRedundantShortforms) : base($InputCommandTokens, $AppliesTo, $Arguments, $Probability) {
        $this.CombineShortForm = $CombineShortForm;
        $this.RandomiseOrder = $RandomiseOrder;
        $this.SwapLongShortForm = $SwapLongShortForm;
        $this.InsertRedundantShortforms = $InsertRedundantShortforms;
    }

    [void]GenerateOutput() {
        if ($this.RandomiseOrder) {
            # 1. Get the objects that match the condition
            $matching = $this.InputCommandTokens.Where({ $this.AppliesTo.Contains($_.Type) -and (-not $_.HasValue) })

            # 2. Extract their TokenContent as an array of char[]
            $tokenArrays = @()
            $matching | ForEach-Object { $tokenArrays += , $_.TokenContent }

            # 3. Create an array of indices and shuffle them
            $indices = 0..($tokenArrays.Count - 1) | Sort-Object { Get-Random }

            # 4. Assign the shuffled arrays back to the matching objects
            $i = 0
            $matching | ForEach-Object { $_.TokenContent = $tokenArrays[$indices[$i++]] }
        }

        if ($this.SwapLongShortForm -and ($null -ne $this.Arguments)) {
            foreach ($Token in $This.InputCommandTokens) {
                $t = [Argument]::GetArgumentDetails($This.Arguments, $Token.TokenContent)
                if (($null -ne $t) -and [Modifier]::CoinFlip($this.Probability)) {
                    $Token.TokenContent = [Modifier]::ChooseRandom($t.Arguments)
                }
            }
        }

        $IsMergeable = { param($Token) $this.AppliesTo.Contains($Token.Type) -and $Token.ToString() -match '^-[^-]$' -and !$Token.HasValue }
        $IsValueMergeable = { param($Token) $this.AppliesTo.Contains($Token.Type) -and $Token.ToString() -match '^-[^-]$' -and $Token.HasValue }

        $redundants = $this.Arguments | Where-Object { $_.Redundant -eq $true -and $_.ValueCount -eq 0 } | ForEach-Object { $_.Arguments | Where-Object { $_ -match '^-\S$' } | ForEach-Object { $_[1] } }


        if ($this.CombineShortForm) {
            $arg_i = -1;
            foreach ($Token in $This.InputCommandTokens) {
                $arg_i += 1;
                # Check if this is one of the mergeable tokens, and with probability merge it
                if ($IsMergeable.Invoke($Token)) {
                    # Create brand new token with the found one, plus all upcoming ones
                    $NewTokenContent = [System.Collections.ArrayList]@($Token.TokenContent);

                    # Add redundant characters
                    if($redundants.Count -gt 0){
                        for ($i = 0; $true; $i = $i + 1) {
                            if ($This.InsertRedundantShortforms -and [Modifier]::CoinFlip($This.Probability * [Math]::Pow(0.9, $i))) {
                                $NewTokenContent.Add([Modifier]::ChooseRandom($redundants))
                            }
                            else {
                                break
                            }
                        }
                    }

                    # Find all upcoming mergable tokens
                    $candidates = ($This.InputCommandTokens | Select-Object -Skip ($arg_i + 1)).Where({ $IsMergeable.Invoke($_) -and [Modifier]::CoinFlip($This.Probability) });
                    if ($candidates.Count -ne 0) {
                        $candidates | ForEach-Object {
                            $NewTokenContent.addRange(@($_.TokenContent | Select-Object -Skip 1));
                            $_.TokenContent = @(); #// Ensures token is 'removed'
                        }
                    }

                    # Randomise order
                    if ($this.RandomiseOrder -and [Modifier]::CommonOptionChars -contains $NewTokenContent[0] ) {
                        $NewTokenContent = [System.Collections.ArrayList]@($NewTokenContent[0]) + ([System.Collections.ArrayList]@($NewTokenContent | Select-Object -Skip 1) | Sort-Object { Get-Random })
                        $NewTokenContent = [System.Collections.ArrayList]$NewTokenContent;
                    }

                    # Find short-form arguments that DO have a value; we can pick at most one, and only add them to the end.
                    $valueCandidates = ($This.InputCommandTokens | Select-Object -Skip ($arg_i + 1) -SkipLast 1 | ForEach-Object { $j = ($arg_i + 2); } { [System.Tuple]::Create($_, $This.InputCommandTokens[$j++]) } ).Where({ $IsValueMergeable.Invoke($_[0]) -and [Modifier]::CoinFlip($This.Probability) })

                    if ($valueCandidates.Length -gt 0) {
                        $valueCandidate = [Modifier]::ChooseRandom($valueCandidates)
                        $NewTokenContent.AddRange(@($valueCandidate[0].TokenContent | Select-Object -Skip 1))
                        $valueCandidate[0].TokenContent = @();
                        $NewTokenContent.AddRange(@($valueCandidate[1].TokenContent))
                        $valueCandidate[1].TokenContent = @();
                    }

                    # Update current token
                    $Token.TokenContent = $NewTokenContent;
                } elseif ($IsValueMergeable.Invoke($Token)){

                    # Create new, empty token
                    $NewTokenContent = [System.Collections.ArrayList]@($Token.TokenContent[0]);

                    # Add redundant characters
                    if($redundants.Count -gt 0){
                        for ($i = 0; $true; $i = $i + 1) {
                            if ($This.InsertRedundantShortforms -and [Modifier]::CoinFlip($This.Probability * [Math]::Pow(0.9, $i))) {
                                $NewTokenContent.Add([Modifier]::ChooseRandom($redundants))
                            }
                            else {
                                break
                            }
                        }
                    }
                    $NewTokenContent.Add($Token.TokenContent[1])
                    $Token.TokenContent = $NewTokenContent
                }
            }

            # Second pass: merge left-over short-form arguments that have a value
            $i = 0;
            foreach ($Token in $This.InputCommandTokens) {
                # Check if this is one of the mergeable tokens, and with probability merge it
                if ($IsValueMergeable.Invoke($Token) -and (($i + 1) -lt $This.InputCommandTokens.Length) -and [Modifier]::CoinFlip($This.Probability)) {
                    $NewTokenContent = @($Token.TokenContent);
                    # Add redundant characters
                    if($redundants.Count -gt 0){
                        for ($j = 0; $true; $j = $j + 1) {
                            if ($This.InsertRedundantShortforms -and [Modifier]::CoinFlip($This.Probability * [Math]::Pow(0.9, $j))) {
                                $NewTokenContent = @($NewTokenContent[0]) + @([Modifier]::ChooseRandom($redundants)) + @($NewTokenContent[1..($NewTokenContent.Count - 1)])
                            }
                            else {
                                break
                            }
                        }
                    }

                    $NewTokenContent = @($NewTokenContent) + @($This.InputCommandTokens[$i + 1].TokenContent);
                    $this.InputCommandTokens[$i + 1].TokenContent = @();
                    $Token.TokenContent = $NewTokenContent;
                }
                $i += 1;
            }
        }
    }
}
