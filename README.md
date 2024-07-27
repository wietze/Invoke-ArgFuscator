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
* **macOS**: If you have `brew` preinstalled, run `brew install powershell/tap/powershell` to install the latest version of PowerShell. For alternative installation options, refer to Microsoft's [documentation].
* **Linux**: Refer to Microsoft's [documentation] to see how you can install PowerShell on your distribution.

### Installation

Simply clone or download the contents of this repository to a folder of choice.

## Usage

1. Make sure you have a model file, in JSON format. These can be generated via [ArgFuscator.net](https://argfuscator.net/) via the 'Download' option; alternatively, you can obtain raw base files via [GitHub](https://github.com/wietze/Argfuscator.net/main/tree/models).
2. Call `Invoke-ArgFuscator.ps1` via PowerShell, e.g.:

   ```bash
   # Windows
   powershell .\Invoke-ArgFuscator.ps1

   # macOS and Linux
   pwsh ./Invoke-ArgFuscator.ps1
   ```

   This will allow you to pass the path to the model file interactively.

   ***Alternatively***, pass the path to the model file as command-line argument, e.g.:

   ```bash
   # Windows
   powershell .\Invoke-ArgFuscator.ps1 "path\to\file.json"

   # macOS and Linux
   pwsh ./Invoke-ArgFuscator.ps1 "path/to/file.json"
   ```

## Integration

Because Invoke-ArgFuscator is a PowerShell module, you can add this project's functionality to your own PowerShell project.

To leverage Invoke-ArgFuscator, add

```pwsh
Import-Module ./Invoke-ArgFuscator.psm1
```

to your PowerShell file, and call it as follows:

```pwsh
Invoke-ArgFuscator -InputFile $InputFile -n $n
```

with `$InputFile` a `string` containing a (relative/absolute) file path to the model file, and `$n` an `integer` greater than 0 for the number of obfuscated command-line equivalents that should be produced.
