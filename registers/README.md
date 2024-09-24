# Register Learning

Let's create some register stuffs. Registers are one of the most important
pieces, so we need to spend some time making sure that we understand what is
going on with them.

Our main function is `register`:

register i s delays the values in Signal s for one cycle, and sets the value at time 0 to i

``` haskell
register :: forall dom a. (HiddenClockResetEnable dom, NFDataX a)	 
         => a -> Signal dom a -> Signal dom a
```

Parameters:

1. Reset value. register outputs the reset value when the reset is active. If
   the domain has initial values enabled, the reset value will also be the
   initial value.
2. Signal. 

Example from Documentation:

``` haskell
>>> sampleN @System 5 (register 8 (fromList [1,1,2,3,4]))
[8,8,1,2,3]
```

Things to note:

- The `initial` value is output 2x times the first time the Register is used /
  clocked / whatever. 
- The `@System` sets the register domain (typically required).
- The `fromList` function simply creates a Signal from a list 
- The `sampleN` function allows us to take a number of samples from the register

## Simple Up Counter

To create a simple up counter:

``` haskell
countUp :: HiddenClockResetEnable dom => Signal dom (Unsigned 4)
countUp = register 0 (counter + 1)
```

Which we can test with `sampleN`:

``` haskell
clashi> sampleN @System 20 countUp
[0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,0,1,2]
```

We can modify the simple counter to be parametrizable using the Type System:

``` haskell
countUp' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => Signal dom (Unsigned n)
countUp' = register 0 (countUp' + 1)
```

Which makes calling the thing a bit more tricky, but we can specify the register
size:

``` haskell
clashi> sampleN 7 (countUp' :: Signal System (Unsigned 2))
[0,0,1,2,3,0,1]
```

We can use `SNat` numbers to parameterize this a bit differently:

``` haskell
countUp'' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => SNat n -> Signal dom (Unsigned n)
countUp'' _ = s
    where s = register 0 (s + 1)
```

Testing:

``` haskell
clashi> sampleN @System 10 (countUp'' (SNat @2))
[0,0,1,2,3,0,1,2,3,0]
clashi> sampleN @System 10 (countUp'' (SNat @3))
[0,0,1,2,3,4,5,6,7,0]
```

## Down Counter

A down counter is pretty easy too:

``` haskell
countDown :: forall a dom. (HiddenClockResetEnable dom)
          => (Eq a, NFDataX a, Num a)
          => a -> Signal dom a
countDown start = counter
    where counter = register start (goDown <$> counter)
          goDown 0 = 0
          goDown i = i - 1
```

Tested:

``` haskell
clashi> sampleN @System 10 $ countDown 10
[10,10,9,8,7,6,5,4,3,2]
clashi> sampleN @System 10 $ countDown 5
[5,5,4,3,2,1,0,0,0,0]
```

Let's create a down counter with a SNat for fun:

``` haskell
countDown' :: forall n dom. (HiddenClockResetEnable dom)
           => KnownNat n
           => SNat n -> Signal dom (Unsigned n)
countDown' _ = counter
    where start = snatToNum (SNat @n)
          counter = counter start (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1
```

Testing:

``` haskell
clashi> sampleN @System 10 $ countDown' (SNat @2)
[2,2,1,0,0,0,0,0,0,0]
clashi> sampleN @System 10 $ countDown' (SNat @3)
[3,3,2,1,0,0,0,0,0,0]
clashi> sampleN @System 10 $ countDown' (SNat @4)
[4,4,3,2,1,0,0,0,0,0]
clashi> sampleN @System 10 $ countDown' (SNat @5)
[5,5,4,3,2,1,0,0,0,0]
```

This is inefficient though: The output bit width increases linearly with n:

``` haskell
clashi> :t countDown' (SNat @3 )
countDown' (SNat @3 )
  :: (KnownDomain dom, ?clock::Clock dom, ?reset::Reset dom,
      ?enable::Enable dom) =>
     Signal dom (Unsigned 3)
clashi> :t countDown' (SNat @4 )
countDown' (SNat @4 )
  :: (KnownDomain dom, ?clock::Clock dom, ?reset::Reset dom,
      ?enable::Enable dom) =>
     Signal dom (Unsigned 4)
```

We can fix this by using the `CLog 2` Type level function maybe (From
GHC.TypeLits.Extra - CLog is Ceiling Log):

``` haskell
countDown'' :: forall n dom. (HiddenClockResetEnable dom)
            => (1 <= n)
            => KnownNat n
            => SNat n -> Signal dom (Unsigned (CLog 2 n))
countDown'' s = counter
    where start = snatToNum s -- Not sure why this is required this way
          counter = register start (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1
```

And the output type is now:

``` haskell
clashi> :t countDown'' (SNat @10)
countDown'' (SNat @10)
  :: (KnownDomain dom, ?clock::Clock dom, ?reset::Reset dom,
      ?enable::Enable dom) =>
     Signal dom (Unsigned (CLog 2 10))
```

TODO - How do I resolve this?

## Debounce

We can use `regEn` with a counter to create a "debouncer". How this debouncer
works: If the `input_signal` changes, then start a counter. If the counter
expires and the `input_signal` has not changed again, then change the output.
Otherwise keep the output the same.

Questions:

- How do I test this?

In short, we have a few inputs:

- Time to wait (`delay`)
- What is the current value (`current`)
- The input signal (`input_signal`)

For simplicity, `delay` will be provided as an `SNat`, but this could easily be
a `ClockDivider` or something in real code.

``` haskell
debounce :: forall n a dom. (HiddenClockResetEnable dom)
         => KnownNat n
         => (NFDataX a, Eq a)
         => SNat n -> a -> Signal dom a -> Signal dom a
debounce delay current input_signal = undefined
```

Firstly, let's make a counter to count down (since it's easy to compare to 0):

``` haskell
    -- Start at Delay and count downwards to 0
    down = countDown'' delay
```

We need to see if the `input_signal` is different from the `current` value. To
do this we need to compare the `input_signal` value to the current value, which
will require a new block:

``` haskell
changed :: HiddenClockResetEnable dom 
        => (Eq a, NFDataX a) 
        => a -> Signal dom a -> Signal dom Bool
changed current input_signal = input_signal ./=. last_known_value
    where last_known_value = register current input_signal
```

We can now tell if the input signal has changed from the previous state, and
have a counter. Let's put it together!

``` haskell
debounce :: forall n a dom. (HiddenClockResetEnable dom)
         => KnownNat n
         => (NFDataX a, Eq a)
         => SNat n -> a -> Signal dom a -> Signal dom a
debounce delay current input_signal = regEn current stable input_signal
    where count = countDown'' delay
          stable = count .==. 0
```

## Improvement: Reload the counter if the state changes 

## Other topics (TODO)

- Debounce (regEn)
- Delay a signal (delay)

## Vector / BitVector Topics

- Create a Vector
- Convert to a BitVector
    - Truncate
    - Convert from a to b
- BitCoerce ?
- Shift

