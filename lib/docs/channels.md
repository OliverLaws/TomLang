# channels

← [All libraries](README.md)

```
use channels
set jobs: list of text = []

thread
    repeat forever
        set job = channels.receive(jobs)
        say "working on {job}"
    end
end

channels.send(jobs, "first")
channels.send(jobs, "second")
wait 1
bye
```

A channel is a list used as a queue: `send` puts a value at the back and `receive` takes one from the front, waiting until there is one. It works between tasks, `every`/`after` blocks, threads and the main program, so they can hand work to each other without sharing loose variables. Make one with any list type: `list of text`, `list of number`, `list of Job`.

`receive` checks again every millisecond while it waits, letting everything else run in between.

| Function | Does |
|---|---|
| `send(channel: list of T, value: T)` | puts `value` at the back |
| `receive(channel: list of T): T` | takes the front value, waiting until there is one |
| `receiveFor(channel: list of T, seconds: decimal): T?` | like `receive`, but gives up after that many seconds and gives back `nothing` |
| `tryReceive(channel: list of T): T?` | takes the front value now, or gives back `nothing` if it's empty |
| `waiting(channel: list of T): number` | how many values are waiting |
