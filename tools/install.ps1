param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$Repo = "TomPro1203/TomLang"
$Home_ = Join-Path $env:LOCALAPPDATA "Programs\TomLang"
$Classes = "HKCU:\Software\Classes"
$Fragment = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\Fragments\TomLang"
$ExtensionId = "tom.tomlang"

function Refresh-Environment {
    Add-Type -Namespace Win -Name Env -MemberDefinition '[DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern System.IntPtr SendMessageTimeout(System.IntPtr h, uint m, System.UIntPtr w, string l, uint f, uint t, out System.UIntPtr r);' -ErrorAction SilentlyContinue
    $result = [System.UIntPtr]::Zero
    [Win.Env]::SendMessageTimeout([System.IntPtr]0xffff, 0x1A, [System.UIntPtr]::Zero, "Environment", 2, 5000, [ref]$result) | Out-Null
    Add-Type -Namespace Win -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, System.IntPtr a, System.IntPtr b);' -ErrorAction SilentlyContinue
    [Win.Shell]::SHChangeNotify(0x08000000, 0, [System.IntPtr]::Zero, [System.IntPtr]::Zero)
}

function Get-UserPath {
    $value = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $value) { return @() }
    return $value.Split(";") | Where-Object { $_ -ne "" }
}

if ($Uninstall) {
    $kept = Get-UserPath | Where-Object { $_.TrimEnd("\") -ne $Home_ }
    [Environment]::SetEnvironmentVariable("Path", ($kept -join ";"), "User")
    Remove-Item "$Classes\.tom" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$Classes\TomLang.File" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $Fragment -Recurse -Force -ErrorAction SilentlyContinue
    if (Get-Command code -ErrorAction SilentlyContinue) { code --uninstall-extension $ExtensionId 2>$null | Out-Null }
    Remove-Item $Home_ -Recurse -Force -ErrorAction SilentlyContinue
    Refresh-Environment
    Write-Host "TomLang removed."
    return
}

function Find-Source {
    $here = if ($PSScriptRoot) { $PSScriptRoot } else { "" }
    foreach ($root in @($here, (Join-Path $here ".."))) {
        if ($root -eq "") { continue }
        foreach ($exe in @((Join-Path $root "tomlang.exe"), (Join-Path $root "build\tomlang.exe"))) {
            if ((Test-Path $exe) -and (Test-Path (Join-Path $root "lib"))) {
                return @{ Exe = $exe; Root = (Resolve-Path $root).Path }
            }
        }
    }
    return $null
}

$source = Find-Source
if ($null -eq $source) {
    Write-Host "Downloading the latest TomLang..."
    $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "TomLang-installer" }
    $asset = $release.assets | Where-Object { $_.name -like "*.zip" } | Select-Object -First 1
    if ($null -eq $asset) { throw "The latest release has no .zip to download." }
    $temp = Join-Path ([IO.Path]::GetTempPath()) ("TomLang-" + [Guid]::NewGuid())
    New-Item -ItemType Directory -Path $temp | Out-Null
    $zip = Join-Path $temp $asset.name
    Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing
    Expand-Archive $zip -DestinationPath $temp -Force
    $found = Get-ChildItem $temp -Recurse -Filter tomlang.exe | Select-Object -First 1
    if ($null -eq $found) { throw "The download didn't contain tomlang.exe." }
    $source = @{ Exe = $found.FullName; Root = $found.DirectoryName }
}

Write-Host "Installing to $Home_"
New-Item -ItemType Directory -Path $Home_ -Force | Out-Null
Copy-Item $source.Exe (Join-Path $Home_ "tomlang.exe") -Force
Remove-Item (Join-Path $Home_ "lib") -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item (Join-Path $source.Root "lib") (Join-Path $Home_ "lib") -Recurse -Force
$iconSource = @((Join-Path $source.Root "tomlang.ico"), (Join-Path $source.Root "assets\tomlang.ico")) | Where-Object { Test-Path $_ } | Select-Object -First 1
$icon = Join-Path $Home_ "tomlang.ico"
if ($iconSource) { Copy-Item $iconSource $icon -Force }
$vsix = Get-ChildItem $source.Root -Recurse -Filter "tomlang-*.vsix" -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -Last 1
$installer = Join-Path $Home_ "install.ps1"
$packedInstaller = @((Join-Path $source.Root "install.ps1"), (Join-Path $source.Root "tools\install.ps1")) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($PSCommandPath -and ((Resolve-Path $PSCommandPath).Path -ne $installer)) { Copy-Item $PSCommandPath $installer -Force }
elseif ($packedInstaller -and ((Resolve-Path $packedInstaller).Path -ne $installer)) { Copy-Item $packedInstaller $installer -Force }
$exe = Join-Path $Home_ "tomlang.exe"

$paths = Get-UserPath
if (-not ($paths | Where-Object { $_.TrimEnd("\") -eq $Home_ })) {
    [Environment]::SetEnvironmentVariable("Path", (($paths + $Home_) -join ";"), "User")
}
if (-not (($env:Path -split ";") -contains $Home_)) { $env:Path = "$env:Path;$Home_" }

New-Item -Path "$Classes\.tom" -Force | Out-Null
Set-Item -Path "$Classes\.tom" -Value "TomLang.File"
New-Item -Path "$Classes\TomLang.File" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File" -Value "TomLang File"
New-Item -Path "$Classes\TomLang.File\DefaultIcon" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File\DefaultIcon" -Value "`"$icon`""
New-Item -Path "$Classes\TomLang.File\shell\open\command" -Force | Out-Null
Set-Item -Path "$Classes\TomLang.File\shell\open" -Value "Run with TomLang"
Set-ItemProperty -Path "$Classes\TomLang.File\shell\open" -Name "Icon" -Value "`"$icon`""
Set-Item -Path "$Classes\TomLang.File\shell\open\command" -Value "cmd /k `"`"$exe`" `"%1`"`""

New-Item -ItemType Directory -Path $Fragment -Force | Out-Null
$profile_ = @{
    profiles = @(@{
        guid = "{5b7f3c2a-9d41-4e8b-a6c0-2f1e8d7b4a93}"
        name = "TomLang"
        commandline = "`"$exe`""
        icon = $icon
        startingDirectory = "%USERPROFILE%"
    })
}
$profile_ | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $Fragment "tomlang.json") -Encoding UTF8

if ($vsix -and (Get-Command code -ErrorAction SilentlyContinue)) {
    Write-Host "Installing the VS Code extension..."
    code --install-extension $vsix.FullName --force | Out-Null
}

Refresh-Environment
Write-Host ""
Write-Host "TomLang is installed."
Write-Host "  Open a new terminal and type:  tomlang game.tom"
Write-Host "  Double-click any .tom file to run it."
Write-Host "  Windows Terminal has a new 'TomLang' profile in its dropdown."
Write-Host "  To remove it:  powershell -ExecutionPolicy Bypass -File `"$installer`" -Uninstall"
