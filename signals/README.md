# Signal Learning

The most important aspect - Signals are a super cool data type that dictates a
lot of interesting stuff about our system.

So how do we work with Signals? Let's make one!

``` bash
clashi> let x = pure 1 :: Signal System (Unsigned 8)
clashi> sampleN 10 x
[1,1,1,1,1,1,1,1,1,1]
```

Interesting! By a Signal of `pure 1` is a continuous signal that always returns
a 1 (in this case, an Unsigned 8 bit '1').

What are some cool properties of Signals?

- Functor (`fmap`)
- Applicative (`pure`, `<*>`)
- Foldable (`foldr`)
- Num (`+`, `-`, `*`, `negate`, `abs`)
- Fractional (`\`) 

All pretty common. Let's try some stuff out:

``` bash
```

## Converting to / from Vectors

We can also make a signal from a list:

``` bash
clashi> let y = fromList [2..] :: Signal System (Unsigned 8)
```

## Logical Operations
## Bundling
## 

