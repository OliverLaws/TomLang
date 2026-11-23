# strings

← [All libraries](README.md)

```
use strings
say strings.padStart("7", 3, "0")
say strings.titleCase("the big dog")
say strings.count("banana", "an")
```

The everyday ones are built into all text, so they need no `use`: `t.split(",")`, `t.upper()`, `t.lower()`, `t.trim()`, `t.replace("a", "b")`, `t.contains("x")`, `t.startsWith("x")`, `t.endsWith("x")`. They're in this library too (`strings.split(t, ",")`) for pipelines like `t |> strings.trim`.

Positions start at 1, like everywhere else in TomLang. Functions that search give back `nothing` when there's no match.

## Searching

| Function | Does |
|---|---|
| `indexOf(source: text, find: text, startPos: number = 1): number?` | where `find` first appears: `indexOf("hello", "l")` is `3` |
| `lastIndexOf(source: text, find: text): number?` | where it last appears: `lastIndexOf("hello", "l")` is `4` |
| `contains(source: text, find: text): bool` | true if `find` is anywhere in it |
| `startsWith(source: text, prefix: text): bool` | `startsWith("hello", "he")` is `true` |
| `endsWith(source: text, suffix: text): bool` | `endsWith("file.tom", ".tom")` is `true` |
| `count(source: text, find: text): number` | how many times it appears, without overlaps: `count("banana", "an")` is `2` |

## Checking

| Function | Does |
|---|---|
| `isEmpty(source: text): bool` | true for `""` |
| `isBlank(source: text): bool` | true if it's only spaces, tabs and new lines |
| `isSpace(character: text): bool` | true for a space, tab or new line |
| `isLetter(character: text): bool` | true for A to Z and a to z |
| `isDigit(character: text): bool` | true for 0 to 9 |
| `isLetters(source: text): bool` | true if every character is a letter |
| `isDigits(source: text): bool` | true if every character is a digit |
| `isLettersOrDigits(source: text): bool` | true if every character is a letter or digit |
| `isUpper(source: text): bool` | true if it has letters and they're all capitals (`"HI 2"` is true) |
| `isLower(source: text): bool` | true if it has letters and they're all lowercase |

## Splitting and joining

| Function | Does |
|---|---|
| `split(source: text, separator: text): list of text` | `split("a,b,,c", ",")` is `["a", "b", "", "c"]`; an empty separator gives the letters |
| `splitOnce(source: text, separator: text): list of text` | splits at the first one: `splitOnce("key=a=b", "=")` is `["key", "a=b"]` |
| `rsplitOnce(source: text, separator: text): list of text` | splits at the last one: `["key=a", "b"]` |
| `join(pieces: list of text, separator: text = ""): text` | `join(["a", "b"], "-")` is `a-b` (same as `pieces.join("-")`) |
| `lines(source: text): list of text` | splits into lines (works with Windows and Linux line ends) |
| `words(source: text): list of text` | splits on any spaces and drops empty bits: `words("  a   b ")` is `["a", "b"]` |
| `chars(source: text): list of text` | every character: `chars("hé")` is `["h", "é"]` |

## Trimming and padding

| Function | Does |
|---|---|
| `trim(source: text): text` | removes spaces, tabs and new lines from both ends |
| `trimStart(source: text): text` | from the start only |
| `trimEnd(source: text): text` | from the end only |
| `trimChars(source: text, charsToRemove: text): text` | removes any of those characters from both ends: `trimChars("--hi--", "-")` is `hi` |
| `padStart(source: text, width: number, padWith: text = " "): text` | `padStart("42", 5, "0")` is `00042` |
| `padEnd(source: text, width: number, padWith: text = " "): text` | `padEnd("ab", 4, ".")` is `ab..` |
| `centre(source: text, width: number, padWith: text = " "): text` | `centre("hi", 6, "*")` is `**hi**` |

## Changing text

| Function | Does |
|---|---|
| `upper(source: text): text` | `upper("hello")` is `HELLO` (A to Z only) |
| `lower(source: text): text` | `lower("HeLLo")` is `hello` |
| `capitalise(source: text): text` | `capitalise("hELLO")` is `Hello` |
| `titleCase(source: text): text` | `titleCase("the quick fox")` is `The Quick Fox` |
| `swapCase(source: text): text` | `swapCase("Hello")` is `hELLO` |
| `normaliseWhitespace(source: text): text` | squashes spaces: `"  a   b "` becomes `a b` |
| `replace(source: text, find: text, replaceWith: text): text` | replaces every one: `replace("cat hat", "at", "og")` is `cog hog` |
| `replaceFirst(source: text, find: text, replaceWith: text): text` | only the first one |
| `replaceLast(source: text, find: text, replaceWith: text): text` | only the last one |
| `repeatText(source: text, times: number): text` | `repeatText("ab", 3)` is `ababab` |
| `reverseText(source: text): text` | `reverseText("héllo")` is `olléh` |
| `truncate(source: text, maxLength: number, ending: text = "..."): text` | `truncate("hello world", 8)` is `hello...` |
| `wrap(source: text, lineWidth: number): list of text` | breaks text into lines no longer than `lineWidth`, between words |

## Cutting pieces out

| Function | Does |
|---|---|
| `charAt(source: text, position: number): text?` | the character there, or `nothing` if it's past the end |
| `slice(source: text, startPos: number, endPos: number = -1): text` | `slice("hello", 2, 4)` is `ell`; leave out `endPos` to go to the end |
| `take(source: text, amount: number): text` | the first few: `take("hello", 2)` is `he` |
| `drop(source: text, amount: number): text` | all but the first few: `drop("hello", 2)` is `llo` |
| `removePrefix(source: text, prefix: text): text` | `removePrefix("unhappy", "un")` is `happy` |
| `removeSuffix(source: text, suffix: text): text` | `removeSuffix("file.tom", ".tom")` is `file` |
| `between(source: text, startMarker: text, endMarker: text): text?` | `between("say (hi) now", "(", ")")` is `hi` |
