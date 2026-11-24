# http

← [All libraries](README.md)

```
use http
use json
set reply = http.get("https://api.github.com/users/tompro1203")
say reply.status
say reply.json()

set data = http.getJson("https://api.github.com/users/tompro1203")
say json.pick(data, "public_repos")
```

Windows only (it uses Windows' own WinHTTP, so https, proxies and gzip just work). A request that can't reach the server fails with a message saying why (`timed out`, `server name not found`, `can't connect`...), so use `try` where the network might be down. A reply with a bad status (404, 500) does **not** fail: check `.ok` or `.status`. Requests wait for the reply, so put slow ones in a `thread` if the rest of the program should keep going.

## Response

| Field / method | Is |
|---|---|
| `status: number` | the status code: `200`, `404`... |
| `ok: bool` | true for 200 to 299 |
| `body: text` | what came back |
| `headers: dictionary of text` | reply headers, names in small letters: `reply.headers["content-type"]` |
| `json(): json.Json` | the body read as JSON |
| `header(name: text): text?` | one header, any capitals, or `nothing` |

## Requests

Every one takes `headers: dictionary of text = {}` and `timeout: decimal = 30` (seconds) at the end.

| Function | Does |
|---|---|
| `get(url: text)` | GET |
| `post(url: text, body: text = "")` | POST some text |
| `put(url: text, body: text = "")` | PUT |
| `patch(url: text, body: text = "")` | PATCH |
| `delete(url: text)` | DELETE |
| `head(url: text)` | only the status and headers |
| `request(method: text, url: text, body: text = "")` | any method |

## JSON and Forms

| Function | Does |
|---|---|
| `getJson(url: text): json.Json` | GET and read the reply as JSON; fails if the status isn't ok |
| `postJson(url: text, data: json.Json): Response` | sends `data` as JSON (adds `Content-Type: application/json`) |
| `putJson(url: text, data: json.Json): Response` | the same with PUT |
| `patchJson(url: text, data: json.Json): Response` | the same with PATCH |
| `postForm(url: text, fields: dictionary of text): Response` | sends fields like an HTML form |

## Files

| Function | Does |
|---|---|
| `download(url: text, filePath: text, timeout: decimal = 60): bool` | saves straight to a file (fine for big files); true if the status was ok |
| `getBytes(url: text): list of number` | the reply as bytes; fails if the status isn't ok |
| `uploadFile(url: text, fieldName: text, filePath: text, fields: dictionary of text = {}, timeout: decimal = 60): Response` | sends a file like an HTML upload form |

## URLs

| Function | Does |
|---|---|
| `encodeUrl(value: text): text` | makes text safe inside a URL: `"a b&c"` → `"a%20b%26c"` |
| `decodeUrl(value: text): text` | the other way (`+` becomes a space) |
| `buildUrl(base: text, params: dictionary of text): text` | `buildUrl("https://x.com/search", {"q": "tom lang"})` → `https://x.com/search?q=tom%20lang` |

## Client

Keeps a base URL, headers and a timeout for an API you call a lot.

```
set api = http.client("https://api.example.com/v1")
api.setBearer("my-token")
set reply = api.get("users")
say api.postJson("users", data).status
```

| Function | Does |
|---|---|
| `client(baseUrl: text = "", headers: dictionary of text = {}, timeout: decimal = 30): Client` | makes one |
| `setHeader(name: text, value: text)` | adds a header to every request |
| `setBearer(token: text)` | adds `Authorization: Bearer token` |
| `get` `post` `put` `patch` `delete` `request` `postJson` `putJson` | like the ones above, with a path added to the base URL (a full `https://` URL is used as it is) and the client's headers mixed in |
