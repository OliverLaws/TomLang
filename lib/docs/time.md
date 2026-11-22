# time

← [All libraries](README.md)

```
use time
say time.formatIso(time.nowLocal())

set start = time.clock()
time.sleepSeconds(0.5)
say time.formatDuration(time.secondsSince(start))
```

Two kinds of clock:

- **Wall clock** (`nowSeconds`, `nowLocal`): the real date and time. Can jump if Windows changes the clock.
- **Timing clock** (`clock`): only ever goes up, very precise. Use it for timing and benchmarks: read it before and after, and the difference is how long it took.

"Unix seconds" means seconds since 1 January 1970 (UTC), the number every language and website uses.

## DateTime

```
record DateTime = year, month, day, hour, minute, second, millisecond, weekday
```

Months go 1 to 12. `weekday` goes 0 (Sunday) to 6 (Saturday).

## Clocks & Benchmarking

| Function | Does |
|---|---|
| `nowSeconds(): number` | the current time in Unix seconds |
| `nowMilliseconds(): number` | the current time in Unix milliseconds |
| `clock(): decimal` | a precise clock for timing, in seconds (only the difference between two readings means anything) |
| `clockMilliseconds(): decimal` | the same in milliseconds |
| `secondsSince(startSeconds: decimal): decimal` | seconds since an earlier `clock()`: `secondsSince(start)` |
| `millisecondsSince(startMilliseconds: decimal): decimal` | milliseconds since an earlier `clockMilliseconds()` |

## Sleep

| Function | Does |
|---|---|
| `sleepSeconds(seconds: decimal)` | waits: `sleepSeconds(0.5)` is half a second |
| `sleepMilliseconds(milliseconds: number)` | waits that many milliseconds |

## Date & Time

| Function | Does |
|---|---|
| `nowLocal(): DateTime` | the date and time where you are |
| `nowUtc(): DateTime` | the date and time in UTC |
| `fromUnixSeconds(seconds: number): DateTime` | turns Unix seconds into a date (UTC) |
| `toUnixSeconds(dateTime: DateTime): number` | turns a date back into Unix seconds (treated as UTC) |

## Formatting

| Function | Does |
|---|---|
| `formatIso(dateTime: DateTime): text` | `2026-11-22T17:05:09` |
| `formatDate(dateTime: DateTime): text` | `2026-11-22` |
| `formatUkDate(dateTime: DateTime): text` | `22/11/2026` |
| `formatTime(dateTime: DateTime): text` | `17:05:09` |
| `formatDuration(seconds: decimal): text` | `42.5ms`, `5.2s`, `2m 5s` or `2h 14m 5s` |
| `weekdayName(dateTime: DateTime): text` | `Sunday` |
| `monthName(dateTime: DateTime): text` | `November` |

## Calendar Helpers

| Function | Does |
|---|---|
| `isLeapYear(year: number): bool` | `isLeapYear(2024)` is `true`, `isLeapYear(1900)` is `false` |
| `daysInMonth(year: number, month: number): number` | `daysInMonth(2024, 2)` is `29` |
