# maths

← [All libraries](README.md)

```
use maths
say maths.sqrt(16)
say maths.clamp(15, 0, 10)
```

`numeric` inputs take a number or a decimal, and give back the same kind.

## Constants

| Name | Value |
|---|---|
| `Pi` | 3.141592653589793 |
| `Tau` | 6.283185307179586 (2 × pi) |
| `E` | 2.718281828459045 |
| `DegToRad` | 0.017453292519943295 |
| `RadToDeg` | 57.29577951308232 |

| Function | Does |
|---|---|
| `getPi(decimalPoints: number): text` | pi as text, to as many decimal places as you ask for (`getPi(50)` for 50 places) |
| `getTau(decimalPoints: number): text` | the same for tau |
| `getE(decimalPoints: number): text` | the same for e |

## Basics

| Function | Does |
|---|---|
| `isEven(n: number): bool` | `isEven(4)` is `true` |
| `isOdd(n: number): bool` | `isOdd(4)` is `false` |
| `min(a: numeric, b: numeric): numeric` | the smaller one |
| `max(a: numeric, b: numeric): numeric` | the bigger one |
| `clamp(value: numeric, low: numeric, high: numeric): numeric` | keeps a value between two others: `clamp(15, 0, 10)` is `10` |
| `abs(x: numeric): numeric` | removes the minus: `abs(-4)` is `4` |
| `sign(x: numeric): number` | `-1`, `0` or `1` |
| `approx(a: decimal, b: decimal, tolerance: decimal = 0.0001): bool` | true if two decimals are close enough: `approx(0.1 + 0.2, 0.3)` is `true` |

## Lists

| Function | Does |
|---|---|
| `sum(items: list of numeric): numeric` | adds them all up |
| `product(items: list of numeric): numeric` | multiplies them all together |
| `average(items: list of numeric): decimal` | the mean |
| `median(items: list of numeric): decimal` | the middle value |
| `minOf(items: list of numeric): numeric` | the smallest item |
| `maxOf(items: list of numeric): numeric` | the biggest item |

## Whole numbers

| Function | Does |
|---|---|
| `gcd(a: number, b: number): number` | greatest common divisor: `gcd(12, 18)` is `6` |
| `lcm(a: number, b: number): number` | lowest common multiple: `lcm(4, 6)` is `12` |
| `factorial(n: number): number` | `factorial(5)` is `120` |
| `isPrime(n: number): bool` | `isPrime(7)` is `true` |
| `mulMod(a: number, b: number, mod: number): number` | `(a * b) % mod` without overflowing |
| `powMod(base: number, exp: number, mod: number): number` | `(base ^ exp) % mod` without overflowing |

## Rounding

| Function | Does |
|---|---|
| `floor(x: decimal): number` | rounds down: `floor(2.7)` is `2` |
| `ceil(x: decimal): number` | rounds up: `ceil(2.1)` is `3` |
| `trunc(x: decimal): number` | cuts off the decimals: `trunc(-2.7)` is `-2` |
| `fract(x: decimal): decimal` | just the decimals: `fract(2.75)` is `0.75` |
| `roundTo(x: decimal, places: number): decimal` | `roundTo(3.14159, 2)` is `3.14` |

## Roots and logs

| Function | Does |
|---|---|
| `sqrt(x: decimal): decimal` | square root |
| `cbrt(x: decimal): decimal` | cube root |
| `pow(base: decimal, exponent: decimal): decimal` | power (same as `^` on decimals) |
| `exp(x: decimal): decimal` | e to the power of x |
| `log(x: decimal): decimal` | natural log |
| `log2(x: decimal): decimal` | log base 2 |
| `log10(x: decimal): decimal` | log base 10 |

## Trig

All angles are in radians. Use `toRadians(90)` for degrees.

| Function | Does |
|---|---|
| `sin(radians: decimal): decimal` | |
| `cos(radians: decimal): decimal` | |
| `tan(radians: decimal): decimal` | |
| `asin(x: decimal): decimal` | inverse sin |
| `acos(x: decimal): decimal` | inverse cos |
| `atan(x: decimal): decimal` | inverse tan |
| `atan2(y: decimal, x: decimal): decimal` | the angle to point (x, y), works in every direction |
| `toRadians(degrees: decimal): decimal` | `toRadians(180)` is pi |
| `toDegrees(radians: decimal): decimal` | `toDegrees(Pi)` is `180.0` |
| `wrapAngle(radians: decimal): decimal` | keeps an angle between 0 and tau |

## Game helpers

| Function | Does |
|---|---|
| `lerp(a: decimal, b: decimal, t: decimal): decimal` | the point `t` of the way from a to b: `lerp(0, 10, 0.5)` is `5.0` |
| `inverseLerp(a: decimal, b: decimal, value: decimal): decimal` | how far value is from a to b: `inverseLerp(0, 10, 5)` is `0.5` |
| `remap(value, inLow, inHigh, outLow, outHigh): decimal` | moves a value from one range to another: `remap(5, 0, 10, 0, 100)` is `50.0` |
| `smoothstep(edge0: decimal, edge1: decimal, x: decimal): decimal` | 0 to 1 with a smooth start and end |
| `moveToward(current: decimal, target: decimal, maxDelta: decimal): decimal` | steps towards a target without passing it |
| `hypot(x: decimal, y: decimal): decimal` | length of the long side of a right triangle |
| `distance(x1, y1, x2, y2): decimal` | distance between two 2D points |
| `distance3D(x1, y1, z1, x2, y2, z2): decimal` | distance between two 3D points |
