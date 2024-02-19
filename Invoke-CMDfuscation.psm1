using module "Types\Token.psm1"
using module "Modifiers\CharacterInsertion.psm1"
using module "Modifiers\FilePathTransformer.psm1"
using module "Modifiers\OptionCharSubstitution.psm1"
using module "Modifiers\QuoteInsertion.psm1"
using module "Modifiers\RandomCase.psm1"
using module "Modifiers\Regex.psm1"
using module "Modifiers\Sed.psm1"
using module "Modifiers\Shorthands.psm1"
using module "Modifiers\UrlTransformer.psm1"

param (
    [Parameter(Mandatory = $true)][string]$InputFile,
    [int]$n=1
)
function Parse-Json {
    $JSONData = Get-Content -Path $InputFile | ConvertFrom-Json;
    $ErrorModifiers = @();
    for ($i = 0; $i -lt $n; $i++) {
        $Tokens = [System.Collections.ArrayList]@();
        foreach ($type_value in $JSONData.command) {
            $Token = [Token]::new($type_value.PSObject.Properties.Value.ToCharArray());
            $Token.Type = $type_value.PSObject.Properties.Name;
            $Tokens.Add($Token) | Out-Null;
        }


        foreach ($modifier_params in $JSONData.modifiers.PSObject.Properties) {
            $ModifierName = $modifier_params.Name -replace "^(?i)regex$","RegularExpression"; # Regex is a reserved name, hence this rename for the Modifier class
            $Modifier = ($ModifierName -as [type])

            if ($null -eq $Modifier) {
                if ($ErrorModifiers -cnotcontains $ModifierName) {
                    Write-Error("Modifier {0} could not be found." -f $ModifierName)
                    $ErrorModifiers += $ModifierName;
                }
                continue
            }

            # Create dictionary with arguments and values
            $ModifierArguments = @{InputCommandTokens = [Token[]]$Tokens; ExcludedTypes = [string[]]@() };
            foreach ($param in $modifier_params.Value.PSObject.Properties) {
                if ($ModifierArguments.ContainsKey($param.Name)) {
                    $ModifierArguments[$param.Name] = $param.Value;
                } else {
                    $ModifierArguments.Add($param.Name, $param.Value) | Out-Null;
                }
            }

            # Create an (ordered) list with the arguments to pass
            $ModifierArgumentsList = [System.Collections.ArrayList]@();
            foreach ($Argument in $Modifier.GetConstructors()[0].GetParameters()) {
                $ModifierArgumentsList.Add($ModifierArguments[$Argument.Name]) | Out-Null;
            }

            # Create Modifier object and generate output
            $Modifier = New-Object -TypeName $Modifier.FullName -ArgumentList $ModifierArgumentsList;
            $Modifier.GenerateOutput();
        }

        # Show final result
        $Output = $tokens[0]
        if($Tokens.Count -gt 1){
            ForEach ($Index in (1..($Tokens.Count - 1))) {
                $Output = -join ($Output, $(if (($Tokens[$Index - 1].Type -eq "argument" -or $Tokens[$Index - 1].Type -eq "value") -and ($Tokens[$Index - 1].TokenContent[-1] -eq "=")) { "" } else { " " }), ($Tokens[$Index].ToString()))
            }
        }

        Write-Host($Output);
    }
}

Parse-Json $InputFile $n;
