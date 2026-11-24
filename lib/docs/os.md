# os

← [All libraries](README.md)

```
use os
say os.userName()
say os.arguments()
set result = os.runCommandOutput("dir")
say result.output
```

Windows only for now. Functions that can go wrong fail with a message, so use `try` where you expect problems.

## Environment Variables

Named bits of text Windows gives every program, like `USERPROFILE`, `APPDATA`, `TEMP` and `PATH`. Changes only affect this program and programs it starts.

| Function | Does |
|---|---|
| `getEnv(name: text): text` | the value, or `""` if it isn't set |
| `getEnvOr(name: text, fallback: text): text` | the value, or `fallback` if it's missing or empty |
| `hasEnv(name: text): bool` | true if it's set (even to `""`) |
| `setEnv(name: text, value: text)` | sets or changes it |
| `removeEnv(name: text)` | deletes it |

## Program & Process

| Function | Does |
|---|---|
| `arguments(): list of text` | the words after the script name: `tomlang game.tom easy 3` gives `["easy", "3"]`; `"two words"` in quotes stays together |
| `commandLine(): text` | the whole command line as one text |
| `executablePath(): text` | the full path of `tomlang.exe` |
| `processId(): number` | this program's ID in Task Manager |
| `changeFolder(folderPath: text)` | changes the working folder (doesn't affect `files`, which counts from your script) |
| `exit(code: number)` | stops the program now; `0` means success, anything else means an error |

## Running Programs

Commands run through `cmd.exe`, so anything you can type in a Command Prompt works.

| Function | Does |
|---|---|
| `runCommand(command: text): number` | runs it, waits, and gives back its exit code (`0` usually means it worked) |
| `runCommandOutput(command: text): CommandResult` | runs it hidden and gives back `.output` (what it printed) and `.exitCode` |
| `openWithDefaultApp(pathOrUrl: text)` | opens a file, folder or website the way double-clicking would: `openWithDefaultApp("https://roblox.com")` |

## System Info

| Function | Does |
|---|---|
| `operatingSystem(): text` | `"windows"` |
| `architecture(): text` | `"x64"`, `"arm64"` or `"x86"` |
| `cpuCoreCount(): number` | how many CPU threads the computer has |
| `totalMemoryBytes(): number` | how much RAM the computer has |
| `availableMemoryBytes(): number` | how much RAM is free right now |
| `computerName(): text` | the PC's name |
| `userName(): text` | the Windows user name |
| `tempFolder(): text` | Windows's folder for temporary files |
| `homeFolder(): text` | the user's folder, like `C:\Users\drive` |

## Clipboard

Plain text only; letters outside English (é, emoji) may not come through correctly yet.

| Function | Does |
|---|---|
| `copyToClipboard(content: text)` | puts text on the clipboard, like Ctrl+C |
| `readClipboard(): text` | what's on the clipboard, or `""` if it isn't text |

## Notifications

A pop-up in the corner of the screen (and in Windows' notification list), with sound.

```
os.notify("Build finished", "game.exe is ready")
os.notify("Low health", "drink a potion", "warning", seconds: 10, sound: false)
```

| Function | Does |
|---|---|
| `notify(title: text, message: text, icon: text = "", seconds: decimal = 5, sound: bool = true)` | shows it and carries straight on; the tray icon goes away after `seconds` |
| `notifyAndWait(title: text, message: text, icon: text = "", seconds: decimal = 5, sound: bool = true)` | the same, but waits the `seconds` before carrying on |

- `icon` is `""` or `"app"` (the program's own icon), `"info"`, `"warning"`, `"error"`, `"none"`, or the path of a `.ico` file (if it can't be loaded, the app icon is used).
- Titles over 63 bytes and messages over 255 bytes are cut short.
- `notify` runs on its own thread, so a program that ends straight after waits until the notification is done.
