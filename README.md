# TomLang

A programming language I'm making, written in x86-64 assembly for Windows and maybe other operating systems later on.

## Installing

TomLang runs on 64-bit Windows 10 and 11. Nothing else needs installing.

### The quick way

Open PowerShell and paste:

```
irm https://raw.githubusercontent.com/TomPro1203/TomLang/master/tools/install.ps1 | iex
```

This downloads the latest release and sets everything up.

### From a download

1. Download `TomLang-windows-x64.zip` from the [Releases page](https://github.com/TomPro1203/TomLang/releases) and unzip it.
2. Right-click `install.ps1` and pick **Run with PowerShell**, or run:

```
powershell -ExecutionPolicy Bypass -File install.ps1
```

### From a copy of the repo

Install [MSYS2](https://www.msys2.org), then in an MSYS2 UCRT64 terminal:

```
pacman -S nasm mingw-w64-ucrt-x86_64-gcc
bash build.sh
```

Then:

```
powershell -ExecutionPolicy Bypass -File tools\install.ps1
```

Run it again after rebuilding to update the installed copy.

### Removing it

```
powershell -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\Programs\TomLang\install.ps1" -Uninstall
```
