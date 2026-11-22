# sort

← [All libraries](README.md)

```
use sort
set names = ["Sam", "Tom", "Ann"]
sort.sort(names)
say sort.sorted([3, 1, 2])
say [5, 2, 9] |> sort.sortedDesc
```

Works on any list whose items can be compared with `<`: numbers, decimals, text, and your own records if you give them a `<` operator.

Functions ending in `ed` (`sorted`, `reversed`) give back a new list and leave yours alone. The others change your list.

## Sorting

| Function | Does |
|---|---|
| `sort(items: list of T)` | sorts smallest first (uses `introSort`) |
| `sorted(items: list of T): list of T` | a sorted copy |
| `sortDesc(items: list of T)` | sorts biggest first |
| `sortedDesc(items: list of T): list of T` | a copy, biggest first |

## Specific algorithms

| Function | Does |
|---|---|
| `introSort(items: list of T)` | quicksort that switches to heap sort if it's going badly, and insertion sort for small bits; the best all-rounder |
| `timSort(items: list of T)` | insertion sort on small runs, then merges them; good for nearly sorted data, keeps equal items in order |
| `mergeSort(items: list of T)` | always fast, keeps equal items in order, uses a copy of the list |
| `heapSort(items: list of T, low: number = 1, high: number = -1)` | always fast and needs no extra memory, but equal items can swap |
| `insertionSort(items: list of T, low: number = 1, high: number = -1)` | very fast for small or nearly sorted lists, slow for big ones |
| `countingSort(items: list of number)` | fastest for whole numbers in a small range (scores, ages); a huge range uses a lot of memory |

## Other

| Function | Does |
|---|---|
| `reverse(items: list of T)` | flips the list |
| `reversed(items: list of T): list of T` | a flipped copy |
| `isSorted(items: list of T): bool` | true if it's already smallest first |
| `search(items: list of T, target: T): number?` | position of `target` in any list, or `nothing` |
| `binarySearch(items: list of T, target: T): number?` | position of `target` in a **sorted** list, much faster for big lists, or `nothing` |
