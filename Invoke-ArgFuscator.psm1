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

$OutputEncoding = [ System.Text.Encoding]::UTF8
function Invoke-TokeniseCommand {
    param(
        [string]$InputCommand
    )

    if ($null -eq $InputCommand) { return $null }
    $SeparationChar = ' '
    $QuoteChars = @('"', "'")
    $ValueChars = @('=', ':') 
    $CommonOptionChars = @('/', '-')

    $InQuote = $null
    $InOptionChar = $null 
    [Token[]]$Tokens = @()  # Explicitly type the array as Token[]
    $TokenContent = @()
    $SeenValueChar = $false

    for ($i = 0; $i -lt $InputCommand.Length; $i++) {
        if ($TokenContent.Count -eq 0) { $SeenValueChar = $false }
        $Char = $InputCommand[$i].ToString()
        $InOptionChar = ($TokenContent.Count -eq 0 -and ($CommonOptionChars | Where-Object { $_ -eq $Char })) ? $true : $InOptionChar
        # if (InQuote == null && (Char == this.SeparationChar || (!SeenValueChar && (i == InputCommand.length || !(['\\', '/'].some(x => x == InputCommand[i + 1]))) && this.ValueChars.some(x => x == Char)))) {

        # if (($null -eq $InQuote) -and (
        #     ($Char -eq $SeparationChar) -or (
        #         (-not $SeenValueChar) -and 
        #             ((($i -eq $InputCommand.Length) -or (-not @('\\', '/') -contains $InputCommand[$i + 1])) -and 
        #         $ValueChars.contains($Char))
        #     )
        # )) {
        if (($null -eq $InQuote) -and (
                ($Char -eq $SeparationChar) -or (
                    (-not $SeenValueChar) -and 
                        ((($i -eq $InputCommand.Length) -or (-not @('\\', '/') -contains $InputCommand[$i + 1])) -and 
                    $ValueChars.contains($Char))
                )
            )) {    
            if ($Char -ne $SeparationChar) {
                $TokenContent += $Char
            }

            if ($TokenContent.Count -gt 0) {
                $Tokens += [Token]::new($TokenContent)
            }
            $TokenContent = @()
            $InOptionChar = $false
        }
        else {
            if (($null -ne $InQuote) -and ($Char -eq $InQuote)) {
                $InQuote = $null
            }
            elseif (($null -eq $InQuote) -and ($QuoteChars | Where-Object { $_ -eq $Char })) {
                $InQuote = $Char
            }

            $TokenContent += $Char
        }
        $SeenValueChar = $SeenValueChar -or ($ValueChars | Where-Object { $_ -eq $Char })
    }

    if ($TokenContent.Count -gt 0) {
        $Tokens += [Token]::new($TokenContent)
    }

    # Find matching template, if available
    $Tokens[0].Type = "command"

    $Tokens | Select-Object -Skip 1 | ForEach-Object -Begin { $i = 0 } -Process {
        $TokenText = $_.ToString()
        $_TokenText = $TokenText -replace "(['`"])(.*?)\1", '$2' #Remove any surrounding quotes

        # If previous token ends with a ValueChar, assume this token denotes a 'value' type;
        # or, if no option char present, designate it as 'value', unless overwritten further down
        if (($ValueChars | Where-Object { $Tokens[$i].TokenContent[-1] -eq $_ }) -or -not ($CommonOptionChars | Where-Object { $_TokenText.StartsWith($_) })) {
            $_.Type = 'value'

            # Special case: WMIC
            if ($Tokens[0].ToString() -match 'wmic(\.exe)?'`
                    -and -not ($Tokens[1..($i + 1)] | Where-Object { $_.GetType() -eq 'disabled' })`
                    -and -not ($Tokens[$i].GetType() -eq 'argument' -and ($ValueChars | Where-Object { $Tokens[$i].TokenContent[-1] -eq $_ }))) {
                Write-Host $Tokens[$i]
                $_.Type = 'disabled'
            }
        }

        if ($_TokenText -match '^(?:\\\\[^\\]+|[a-zA-Z]:|\.[\\/])((?:\\[^\\]+)+\\)?([^<>:]*)$' -or $_TokenText -match '^[^<>:]+\.[a-zA-Z0-9]{2,4}$') {
            $_.Type = 'path' # Windows file path format
        }
        if ($_TokenText -match '^(HKLM|HKCC|HKCR|HKCU|HKU|HKEY_(LOCAL_MACHINE|CURRENT_CONFIG|CLASSES_ROOT|CURRENT_USER|USERS))\\?') {
            $_.Type = 'disabled' # Windows Registry
        }
        if ($_TokenText.StartsWith('http:') -or $_TokenText.StartsWith('https:') -or $_TokenText -match '[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d\.[12]?\d?\d') {
            $_.Type = 'url' #URLs (including IP addresses)
        }

        $i++
    }

    $result = @()
    $Tokens | ForEach-Object {
        $hashtable = @{}
        $hashtable[$_.Type] = ($_.TokenContent -join '')
        $result += $hashtable
    }

    return $result
}

function Invoke-ArgFuscator {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromFile")]
        [ValidateScript({ if ((Test-Path $_ -PathType 'Leaf') -and ((Get-Item $_ | Select-Object -Expand Extension) -eq ".json" )) {
                    return $true
                }
                else {
                    throw "Make sure the file exists, and has a '.json' extension."
                } })]
        [string]$InputFile,
        
        [Parameter(Mandatory = $true, ParameterSetName = "FromCommand")]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(ParameterSetName = "FromCommand")]
        [ValidateScript({ 
                $platformPath = Join-Path $PSScriptRoot "models" $_
                if (Test-Path $platformPath -PathType Container) {
                    return $true
                }
                else {
                    throw "Platform '$_' not found. Make sure the platform directory exists in the models folder."
                }
            })]
        [string]$platform = "windows",
        [int]$n = 1
    )
    <#
    .SYNOPSIS
    Obfuscates a command provided in a JSON-formatted configuration file or command string.

    .DESCRIPTION
    Obfuscates a command provided in a JSON-formatted configuration file/command string by applying specified obfuscation options to the provided command.

    .PARAMETER InputFile
    Specifies the path to the JSON-formatted config file.

    .PARAMETER Command
    Specifies the windows command as string

    .PARAMETER platform
    Specifies the platform (windows, linux, macos)

    .PARAMETER n
    Specifies the number of obfuscated commands to generate. Default value is 1.

    .EXAMPLE
    PS> Invoke-Argfuscator some_config.json 5

    .LINK
    https://www.twitter.com/wietze

    .LINK
    https://www.github.com/wietze/Invoke-Argfuscator
#>

    if ($PSCmdlet.ParameterSetName -eq "FromFile") {
        $JSONData = Get-Content -Encoding UTF8 -Path $InputFile | ConvertFrom-Json
    }
    else {
        $CommandData = Invoke-TokeniseCommand $Command
        $cmd = $CommandData[0]["command"]
        $filePath = "$PSScriptRoot\models\$platform\$cmd.json"
        if (Test-Path $filePath) {
            $ModelData = Get-Content -Encoding UTF8 -Path $filePath | ConvertFrom-Json
            # Create a PSCustomObject that matches the expected format
            $JSONData = [PSCustomObject]@{
                "command"   = ($CommandData  | ConvertTo-JSON | ConvertFrom-Json)
                "modifiers" = $ModelData.modifiers
            }
        }
        else {
            Write-Error("Command {0} could not be found in models" -f $cmd)
            return $null
        }
    }
    $ErrorModifiers = @();
    for ($i = 0; $i -lt $n; $i++) {
        $Tokens = [System.Collections.ArrayList]@();
        $OriginalTokens = [System.Collections.ArrayList]@();
        foreach ($type_value in $JSONData.command) {
            $Token = [Token]::new($type_value.PSObject.Properties.Value.ToCharArray());
            $Token.Type = $type_value.PSObject.Properties.Name;
            $Tokens.Add($Token) | Out-Null;

            $Token = [Token]::new($type_value.PSObject.Properties.Value.ToCharArray());
            $Token.Type = $type_value.PSObject.Properties.Name;
            $OriginalTokens.Add($Token) | Out-Null;
        }


        foreach ($modifier_params in $JSONData.modifiers.PSObject.Properties) {
            $ModifierName = $modifier_params.Name -replace "^(?i)regex$", "RegularExpression"; # Regex is a reserved name, hence this rename for the Modifier class
            $Modifier = ($ModifierName -as [type])

            if ($null -eq $Modifier) {
                if ($ErrorModifiers -cnotcontains $ModifierName) {
                    Write-Error("Modifier {0} could not be found." -f $ModifierName)
                    $ErrorModifiers += $ModifierName;
                }
                continue
            }

            # Create dictionary with arguments and values
            $ModifierArguments = @{InputCommandTokens = [Token[]]$Tokens; AppliesTo = [string[]]@() };
            foreach ($param in $modifier_params.Value.PSObject.Properties) {
                if ($ModifierArguments.ContainsKey($param.Name)) {
                    $ModifierArguments[$param.Name] = $param.Value;
                }
                else {
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
        if ($Tokens.Count -gt 1) {
            ForEach ($Index in (1..($Tokens.Count - 1))) {
                $Output = -join ($Output, $(if (($Tokens[$Index - 1].Type -eq "argument" -or $Tokens[$Index - 1].Type -eq "value") -and ($OriginalTokens[$Index - 1].TokenContent[-1] -match '[=:]')) { "" } else { " " }), ($Tokens[$Index].ToString()))
            }
        }

        Write-Output $Output.ToString();
    }
}
