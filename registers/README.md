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

## Simple Counter

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
