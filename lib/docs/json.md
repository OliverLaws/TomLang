# json

← [All libraries](README.md)

```
use json
use files

set save = json.parse(files.readText("save.json"))
say json.pick(save, "player.name")
say json.asNumber(json.pick(save, "player.coins")) + 10

set out: dictionary of json.Json = {"name": "Tom", "scores": [10, 20], "best": nothing}
files.writeText("out.json", json.pretty(out))
```

Every JSON value is a `json.Json`:

```
type Json = number | decimal | text | bool | nothing | list of Json | dictionary of Json
```

| JSON | TomLang |
|---|---|
| `null` | `nothing` |
| `true` / `false` | `bool` |
| `12` | `number` |
| `1.5`, `2e10`, whole numbers too big for a `number` | `decimal` |
| `"hi"` | `text` |
| `[...]` | `list of Json` |
| `{...}` | `dictionary of Json` (keys stay in the order they were written) |

To use a value, either check it (`check value` / `if value is text`) or convert it with the `as` functions below.

## Reading & Writing

| Function | Does |
|---|---|
| `parse(source: text): Json` | turns JSON text into a value; fails with the position if the text isn't valid JSON |
| `stringify(value: Json): text` | turns a value into compact JSON text: `{"a":1}` |
| `pretty(value: Json, indent: number = 2): text` | turns a value into JSON text over several lines, indented |
| `isValid(source: text): bool` | true if the text is valid JSON |

## Finding Values

| Function | Does |
|---|---|
| `pick(value: Json, path: text): Json` | follows a dotted path, with list positions as numbers: `pick(data, "users.1.name")`; gives `nothing` if any step is missing |
| `has(value: Json, path: text): bool` | true if the path leads to a value that isn't `nothing` |
| `kindOf(value: Json): text` | `"null"`, `"bool"`, `"number"`, `"decimal"`, `"text"`, `"list"` or `"dictionary"` |

## Converting Values

Each fails with a clear message ("json: expected text, got number") if the value is the wrong kind.

| Function | Does |
|---|---|
| `asText(value: Json): text` | the value as text |
| `asNumber(value: Json): number` | the value as a whole number (decimals are rounded) |
| `asDecimal(value: Json): decimal` | the value as a decimal (whole numbers are converted) |
| `asBool(value: Json): bool` | the value as true or false |
| `asList(value: Json): list of Json` | the value as a list |
| `asDictionary(value: Json): dictionary of Json` | the value as a dictionary |

## Notes

- Decimals are written the way `say` shows them: about 10 decimal places, with `e+`/`e-` for very big or very small ones. A decimal can come back very slightly different after a round trip.
- `\uXXXX` escapes (including emoji pairs) are read, and control characters are written as `\u00XX`.
