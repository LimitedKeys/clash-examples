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

Let's test `countDown''`:

``` haskell
clashi> sampleN @System 10 $ countDown'' (SNat @10)
[10,10,9,8,7,6,5,4,3,2]
clashi> sampleN @System 10 $ countDown'' (SNat @9)
[9,9,8,7,6,5,4,3,2,1]
clashi> sampleN @System 10 $ countDown'' (SNat @15)
[15,15,14,13,12,11,10,9,8,7]
clashi> sampleN @System 10 $ countDown'' (SNat @8)
[0,0,0,0,0,0,0,0,0,0]
clashi> sampleN @System 10 $ countDown'' (SNat @4)
[0,0,0,0,0,0,0,0,0,0]
clashi> sampleN @System 10 $ countDown'' (SNat @16)
[0,0,0,0,0,0,0,0,0,0]
```

WHOA what's happening!? Why 0's?

Let's calculate the Log:

$$ ceiling of \log_{2}{5} = 3 $$
$$ ceiling of \log_{2}{4} = 2 $$
$$ ceiling of \log_{2}{3} = 2 $$
$$ ceiling of \log_{2}{2} = 1 $$

How many bits to we need to represent the value 4? 0b100 -> 3 bits! But our
quick math calculates 2... so we have to add 1 bit OR use (n - 1) in the code.

This updates our code to be:

``` haskell
countDown'' :: forall n dom. (HiddenClockResetEnable dom)
            => (1 <= n)
            => KnownNat n
            => SNat n -> Signal dom (Unsigned (CLog 2 n))
countDown'' y = counter
    where start = snatToNum y
          counter = register (start - 1) (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1
```

``` haskell
clashi> sampleN @System 10 $ countDown'' (SNat @10)
[9,9,8,7,6,5,4,3,2,1]
clashi> sampleN @System 10 $ countDown'' (SNat @8)
[7,7,6,5,4,3,2,1,0,0]
clashi> sampleN @System 10 $ countDown'' (SNat @4)
[4,4,3,2,1,0,0,0,0,0]
```

Cool beans.

## Debounce

Let's say we want to wait an amount of time if the provided input signal changes
before we update the output signal appropriately - how would we do this?

Firstly, to tell if a signal has changed we can use a register:

``` haskell
changed :: HiddenClockResetEnable dom 
        => (Eq a, NFDataX a) 
        => a -> Signal dom a -> Signal dom Bool
changed current input_signal = input_signal ./=. last_known_value
    where last_known_value = register current input_signal
```

Where `current` is the value of the input signal right now, and the
`input_sigal` is the signal that we want to check. We can see if an input signal
has changed by:

``` haskell
did_change = changed current input_signal
```

Once we know the input signal has changed, we need a timer. The timer should
"Reload" when things change, and count down to 0. (It could count up instead, I
like counting down though).

``` haskell
counter :: HiddenClockResetEnable dom
        => (1 <= n, KnownNat n)
        => SNat n -> Signal dom (Unsigned (1 + (CLog 2 n)))
counter y = register start (getNext (counter y))
    where start = (snatToNum y) - 1
          getNext c = mux did_change (pure start) (goDown <$> c)
          goDown 0 = 0
          goDown v = v - 1
```

This is a _slight_ change from `countDown''` - this count down timer has a
`reload`. 

The `mux` function is nice - it provides `if - else` functionality on `Signal
dom X` values. If our signal `did_change` then we reload our counter with the
`start` value. Otherwise we count down.

We can say that our input signal is `stable` when the time reaches 0:

``` haskell
stable = (pure 0) .==. (counter delay_time)
```

And once the `input_signal` is `stable` we can update the output. We can use the
register with an extra enable (`regEn`) to update the register when this
condition is met:

``` haskell
regEn current stable input_signal
```

Putting it all together:

``` haskell
changed :: HiddenClockResetEnable dom 
        => (Eq a, NFDataX a) 
        => a -> Signal dom a -> Signal dom Bool
changed current input_signal = input_signal ./=. last_known_value
    where last_known_value = register current input_signal

debounce :: forall n a dom. (HiddenClockResetEnable dom)
         => (1 <= n)
         => KnownNat n
         => (NFDataX a, Eq a)
         => SNat n -> a -> Signal dom a -> Signal dom a
debounce delay_time current input_signal = regEn current stable input_signal
    where did_change = changed current input_signal

          counter :: HiddenClockResetEnable dom
                  => (1 <= n, KnownNat n)
                  => SNat n -> Signal dom (Unsigned (CLog 2 n))
          counter y = register start (getNext (counter y))
              where start = (snatToNum y) - 1
                    getNext c = mux did_change (pure start) (goDown <$> c)
                    goDown 0 = 0
                    goDown v = v - 1
          
          stable = (pure 0) .==. (counter delay_time)
```

Let's test it out! We can use the `simulateN` function to provide an input
signal to a function:

``` haskell
clashi> simulateN @System 15 (debounce (SNat @6) 0) [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
[0,0,0,0,0,0,0,0,0,1,1,1,1,1,1]
clashi> simulateN @System 15 (debounce (SNat @8) 0) [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
[0,0,0,0,0,0,0,0,0,0,0,1,1,1,1]
```

Oddly, this doesn't work for 2 or 3?

``` haskell
clashi> simulateN @System 10 (debounce (SNat @2) 0) [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1]
[0,0,0,1,1,1,1,1,1,1]
clashi> simulateN @System 10 (debounce (SNat @3) 0) [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1]
[0,0,0,1,1,1,1,1,1,1]
```

Maybe 2 or 3 is lower than the propogation deley so it can't be done? or
something like that. Will need to check somehow? VERILATOR. TODO.

## Other topics (TODO)

- Verilate the Debouncer and investivate what happens at 2 and 3

## Vector / BitVector Topics

- Create a Vector
- Convert to a BitVector
    - Truncate
    - Convert from a to b
- BitCoerce ?
- Shift

