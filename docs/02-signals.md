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
clashi> let x = pure 1 :: Signal System (Unsigned 8)
clashi> let y = pure 1 :: Signal System (Unsigned 8)
clashi> let z = x + y
clashi> :t z
z :: Signal System (Unsigned 8)
clashi> z
2 2 2 2 ...
clashi> x - y
0 0 0 0 ...
clashi> x * y 
1 1 1 1 ...
clashi> xx = pure 1 :: Signal System (Unsigned 6)
clashi> x + x2

<interactive>:17:5: error:
    • Couldn't match type ‘6’ with ‘8’
      Expected: Signal System (Unsigned 8)
        Actual: Signal System (Unsigned 6)
    • In the second argument of ‘(+)’, namely ‘x2’
      In the expression: x + x2
      In an equation for ‘it’: it = x + x2
```

Ok basic stuff works, and we can't add things of different types.

We can also make a signal from a list:

``` bash
clashi> let y = fromList [2..] :: Signal System (Unsigned 8)
clashi> y
2 3 4 ... 253 254 255 *** Exception: X: finite list
CallStack (from HasCallStack):
  errorX, called at src/Clash/Signal/Internal.hs:1693:57 in clash-prelude-1.8.1-72gLWAPSXgPDozrrxr9IhV:Clash.Signal.Internal
```

Our list is finite, so we get an error. That's so good to know.

## Bundle / Unbundle

Check out:

    https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Prelude.html#t:Bundle

One useful property of signals is "bundling", which is simple in it's type
declaration:

    bundle :: (Signal dom a, Signal dom b) -> Signal dom (a,b)
    unbundle :: Signal dom (a,b) -> (Signal dom a, Signal dom b)

So we should be able to combine two signals into a single signal that's a tuple
by using `bundle`:

``` haskell
clashi> let x = pure 1 :: Signal System (Unsigned 8)
clashi> let y = pure 2 :: Signal System (Unsigned 8)
clashi> let z = bundle (x,y)
clashi> z
(1,2) (1,2) ...
```

And we should be able to `unbundle` it as well:

``` haskell
clashi> (a, b) = unbundle z
clashi> a
1 1 1 1 ...
clashi> b
2 2 2 2 ...
```

This is useful for packaging signals together for use in Simulation / Testing
functions. Some of the testing functions (like `simulate`) only tolerate a
single output signal. So it is required to bundle the signal together before
`simulate` can be called.

This is also helpful somewhat in function definitions - you only have to write a
single `Signal dom` with a tuple of things to return.

``` haskell
byteToNibbles :: forall dom. (HiddenClockReset dom) 
              => Signal dom (Unsigned 8)
              -> Signal dom (Unsigned 4, Unsigned 4)
```

## Pure Functions and Signals

There's a few ways to work with signals of course. What I prefer is to `fmap` my
function when I can:

``` haskell
magicBlock :: forall dom. (HiddenClockReset dom)
           => Signal dom (Unsigned 8)
           -> Signal dom (Unsigned 8)
magicBlock x = fmap magic x
    where magic v = v + 1
```

In this case, our magic function (which adds 1 to the provided Unsigned 8
number) is mapped using the Functor `fmap` function. 

Where I need to work with a few signals, I like to use `lift` to "lift" the
function into the Type:

``` haskell
magicBlock' :: forall dom. (HiddenClockReset dom)
            -> Signal dom (Unsigned 8)
            => Signal dom (Unsigned 8)
magicBlock' a = liftA2 magic a b
    where b = register 0 (b+1)
          magic x y = x + y
```

In this case our magic function (which adds the two signals together) is
"lifted" into the Signal type, and adds the input signal to our register. This
could be done using a plain old `+` but whatever.


