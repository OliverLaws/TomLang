$Root = Split-Path -Parent $PSScriptRoot
$Exe = Join-Path $Root "build\tomlang.exe"
$Icon = Join-Path $Root "assets\tomlang.ico"
$Classes = "HKCU:\Software\Classes"

New-Item -Path "$Classes\.tom" -Force | Out-Null
Set-Item -Path "$Classes\.tom" -Value "TomLang.File"

New-Item -Path "$Classes\TomLang.File" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File" -Value "TomLang File"

New-Item -Path "$Classes\TomLang.File\DefaultIcon" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File\DefaultIcon" -Value "`"$Icon`""

New-Item -Path "$Classes\TomLang.File\shell\run" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File\shell\run" -Value "Run with TomLang"
Set-ItemProperty -Path "$Classes\TomLang.File\shell\run" -Name "Icon" -Value "`"$Icon`""
New-Item -Path "$Classes\TomLang.File\shell\run\command" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File\shell\run\command" -Value "cmd /k `"`"$Exe`" `"%1`"`""

Add-Type -Namespace Win -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, System.IntPtr a, System.IntPtr b);'
[Win.Shell]::SHChangeNotify(0x08000000, 0, [System.IntPtr]::Zero, [System.IntPtr]::Zero)

Write-Host "Done: .tom files now show the TomLang icon and 'TomLang File'."
