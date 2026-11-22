# files

← [All libraries](README.md)

```
use files
files.writeFile("save.txt", "score: 10")
say files.readFile("save.txt")
say files.listFilesInFolder(".")
```

Anything that can go wrong (a missing file, no permission) fails with a clear message, so wrap it in `try` if you expect problems:

```
try
    say files.readFile("settings.txt")
otherwise
    say "no settings yet"
end
```

Paths can use `\` or `/`. Windows only for now.

A path that doesn't start with a drive (`C:\`) starts from the folder of the script you ran, so `files.readFile("test.txt")` finds the `test.txt` next to your script, wherever you run it from. `../` goes up a folder. A library that wants its own files uses the built-in `here` (the folder of the file it's written in): `files.readFile(here + "/levels.txt")`.

## Reading

| Function | Does |
|---|---|
| `readFile(filePath: text): text` | the whole file as text |
| `readLines(filePath: text): list of text` | the file split into lines (works with Windows and Linux line ends) |
| `readBytes(filePath: text): list of number` | the raw bytes, each 0 to 255 |

## Writing

| Function | Does |
|---|---|
| `writeFile(filePath: text, content: text)` | makes the file, or replaces what's in it |
| `appendFile(filePath: text, content: text)` | adds to the end, making the file if it's missing |
| `writeLines(filePath: text, lines: list of text)` | writes a list, one item per line |
| `writeBytes(filePath: text, bytes: list of number)` | writes raw bytes (0 to 255) |

## Checking

| Function | Does |
|---|---|
| `pathExists(path: text): bool` | true if a file or folder is there |
| `fileExists(filePath: text): bool` | true if it's a file |
| `folderExists(folderPath: text): bool` | true if it's a folder |
| `fileSizeBytes(filePath: text): number` | size in bytes |
| `lastModifiedSeconds(filePath: text): number` | when it was last changed, in seconds since 1970 |
| `isFileEmpty(filePath: text): bool` | true if the file has 0 bytes |
| `isFolderEmpty(folderPath: text): bool` | true if the folder has nothing in it |

## Copying, moving and deleting

| Function | Does |
|---|---|
| `copyFile(sourcePath: text, destinationPath: text)` | copies a file, replacing the destination if it's there |
| `moveFile(sourcePath: text, destinationPath: text)` | moves a file, even to another drive, replacing the destination |
| `renamePath(currentPath: text, newPath: text)` | renames a file or folder (fails if the new name is taken) |
| `deleteFile(filePath: text)` | deletes a file (no recycle bin) |

## Folders

| Function | Does |
|---|---|
| `createFolder(folderPath: text)` | makes one folder; does nothing if it's already there |
| `createFolderTree(folderPath: text)` | makes a folder and any missing folders above it: `"saves\\2026\\june"` |
| `deleteEmptyFolder(folderPath: text)` | deletes a folder that has nothing in it |
| `deleteFolderAndContents(folderPath: text)` | deletes a folder and everything inside it (careful) |
| `listFolderEntries(folderPath: text): list of text` | names of everything inside |
| `listFilesInFolder(folderPath: text): list of text` | names of the files inside |
| `listFoldersInFolder(folderPath: text): list of text` | names of the folders inside |
| `listAllFilesRecursive(folderPath: text): list of text` | full paths of every file inside, including inside sub-folders |

## Paths

These only work on the text of a path; the file doesn't need to exist.

| Function | Does |
|---|---|
| `joinPath(parts: list of text): text` | `joinPath(["C:\\Games", "save.txt"])` is `C:\Games\save.txt` |
| `fileName(filePath: text): text` | `fileName("C:\\Games\\save.txt")` is `save.txt` |
| `fileExtension(filePath: text): text` | `fileExtension("save.tar.gz")` is `.gz` (empty if there isn't one) |
| `fileNameWithoutExtension(filePath: text): text` | `fileNameWithoutExtension("C:\\save.txt")` is `save` |
| `replaceExtension(filePath: text, newExtension: text): text` | `replaceExtension("save.txt", "json")` is `save.json` |
| `parentFolder(path: text): text` | `parentFolder("C:\\Games\\save.txt")` is `C:\Games` |
| `normalisePath(path: text): text` | tidies a path: `C:/Games/./a/../b` is `C:\Games\b` |
| `isAbsolutePath(path: text): bool` | true for `C:\...` and `\\server\...`, false for `saves\a.txt` |
| `workingFolder(): text` | the folder the program was started from (what Python and C count paths from) |
