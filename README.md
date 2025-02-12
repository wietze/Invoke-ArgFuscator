```
░█░█▄░█░█▒█░▄▀▄░█▄▀▒██▀░▒░ ▄▀▄▒█▀▄░▄▀▒▒█▀░█▒█░▄▀▀░▄▀▀▒▄▀▄░▀█▀░▄▀▄▒█▀▄░
░█░█▒▀█░▀▄▀░▀▄▀░█▒█░█▄▄░▀▀░█▀█░█▀▄░▀▄█░█▀░▀▄█▒▄██░▀▄▄░█▀█░▒█▒░▀▄▀░█▀▄░
```

# Invoke-ArgFuscator

Invoke-ArgFuscator is an open-source, cross-platform PowerShell module that helps generate obfuscated command-lines for common system-native executables.

👉 **Use the interactive version of ArgFuscator on [ArgFuscator.net](https://argfuscator.net/)** 🚀

## Summary

Command-Line Obfuscation ([T1027.010](https://attack.mitre.org/techniques/T1027/010/)) is the masquerading of a command's true intention through the manipulation of a process' command line. Across [Windows](https://www.wietzebeukema.nl/blog/windows-command-line-obfuscation), Linux and MacOS, many applications parse passed command-line arguments in unexpected ways, leading to situations in which insertion, deletion and/or subsitution of certain characters does not change the program's execution flow. Successful command-line obfuscation is likely to frustrate defensive measures such as AV and EDR software, in some cases completely bypassing detection altogether.

Although previous research has highlighted the risks of command-line obfuscation, mostly with anecdotal examples of vulnerable (system-native) applications, there is an knowledge vacuum surrounding this technique. This project aims to overcome this by providing a centralised resource that documents and demonstrates various command-line obfuscation techniques, and records the subsceptability of popular applications for each.

## Usage

### Prerequisites

This module works on any operating system supporting PowerShell/pwsh; this includes Windows, macOS and Linux.

* **Windows**: If you are using a Microsoft-supported version of Windows, such as Windows 10 or Windows 11, PowerShell will be pre-installed on your device.
* **macOS**: If you have `brew` preinstalled, run `brew install powershell/tap/powershell` to install the latest version of PowerShell. For alternative installation options, refer to Microsoft's [documentation](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-macos).
* **Linux**: Refer to Microsoft's [documentation](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux) to see how you can install PowerShell on your distribution.

### Installation & usage

1. The simplest way to install this module is via the following PowerShell command:

   ```pwsh
   Install-Module -Name Invoke-ArgFuscator
   ```

2. To use the module, call the function `Invoke-ArgFuscator` from within PowerShell, for example:

   a. To pass a command line you want to obfuscate as a command-line argument (assuming it is supported by [ArgFuscator.net](https://github.com/wietze/Argfuscator.net)):

      ```bash
      # Windows
      powershell /c "Invoke-ArgFuscator -Command 'certutil /f /urlcache https://www.example.org/ homepage.txt'"

      # macOS and Linux
      pwsh -c "Invoke-ArgFuscator -Command 'certutil /f /urlcache https://www.example.org/ homepage.txt'"
      ```

   b. To use your own model files[^1]:

      ```bash
      # Windows
      powershell /c "Invoke-ArgFuscator -InputFile path\to\file.json"

      # macOS and Linux
      pwsh -c "Invoke-ArgFuscator -InputFile path/to/file.json"
      ```

## Local Development

1. Clone this repository to your device.
2. Call `Invoke-ArgFuscator.ps1` via PowerShell, for example:

   a. To run interactively pass the path of a model file[^1] via the standard input (stdin):

      ```bash
      # Windows
      powershell .\Invoke-ArgFuscator.ps1

      # macOS and Linux
      pwsh ./Invoke-ArgFuscator.ps1
      ```

   b. To pass the path to the model file[^1] as a command-line argument:

      ```bash
      # Windows
      powershell .\Invoke-ArgFuscator.ps1 -InputFile "path\to\file.json"

      # macOS and Linux
      pwsh ./Invoke-ArgFuscator.ps1 -InputFile "path/to/file.json"
      ```

   c. To pass a command line you want to obfuscate as a command-line argument:

      *Note that this requires the [models/](https://github.com/wietze/ArgFuscator.net/tree/main/models) folder to be present in the same folder as `Invoke-ArgFuscator.ps1`.*

      ```bash
      # Windows
      powershell .\Invoke-ArgFuscator.ps1 -Command "certutil /f /urlcache https://www.example.org/ homepage.txt"

      # macOS and Linux
      pwsh ./Invoke-ArgFuscator.ps1 -Command "certutil /f /urlcache https://www.example.org/ homepage.txt"
      ```

## Integration

Because Invoke-ArgFuscator is a PowerShell module, you can add this project's functionality to your own PowerShell project.

To leverage Invoke-ArgFuscator, add

```pwsh
Import-Module Invoke-ArgFuscator
```

to your PowerShell file, and call it as either of the following:

```pwsh
Invoke-ArgFuscator -InputFile $InputFile -n $n
Invoke-ArgFuscator -Command $Command -Platform $Platform -n $n
```

with

* `$InputFile` a `string` containing a (relative/absolute) file path to the model file, and `$n` an `integer` greater than 0 for the number of obfuscated command-line equivalents that should be produced (optional); or,
* `$Command` a `string` containing the command line you wish to obfuscate, `$Platform` a `string` with the relevant platform (e.g. `windows`, optional), and `$n` an `integer` greater than 0 for the number of obfuscated command-line equivalents that should be produced (optional).

[^1]: These can be generated via [ArgFuscator.net](https://argfuscator.net/) via the 'Download' option, or downloaded from [GitHub](https://github.com/wietze/Argfuscator.net/tree/main/models).
