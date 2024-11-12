
module Play.Registers where

import Clash.Prelude
import Clash.Annotations.TH

-- Simple Example, Count up to 2^4
countUp :: HiddenClockResetEnable dom => Signal dom (Unsigned 4)
countUp = register 0 (countUp + 1)

-- Simple Example, Count up to 2^n
countUp' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => Signal dom (Unsigned n)
countUp' = register 0 (countUp' + 1)

-- Count up to 2^n
countUp'' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => SNat n -> Signal dom (Unsigned n)
countUp'' _ = s
    where s = register 0 (s + 1)

-- Count up to (Threshold - 1)
--
-- log2 4 = 2, which can represent 0, 1, 2, and 3
--
-- Requires ScopedTypeVariables to pass `n` to the internal SNat. This extension
-- requies that `n` be declared in the `forall` statement.
countUp''' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) 
           => (1 <= n)
           => SNat n
           -> Signal dom (Unsigned (CLog 2 n))
countUp''' _ = counter
    where counter = register 0 (goUp <$> counter)
          threshold = fromInteger $ snatToInteger (SNat @n) - 1
          goUp v = if v < threshold then v + 1 else 0

countDown :: forall a dom. (HiddenClockResetEnable dom)
          => (Eq a, NFDataX a, Num a)
          => a -> Signal dom a
countDown start = counter
    where counter = register start (goDown <$> counter)
          goDown 0 = 0
          goDown i = i - 1

countDown' :: forall n dom. (HiddenClockResetEnable dom)
           => KnownNat n
           => SNat n -> Signal dom (Unsigned n)
countDown' _ = counter
    where start = snatToNum (SNat @n)
          counter = register start (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1

countDown'' :: forall n dom. (HiddenClockResetEnable dom)
            => (1 <= n)
            => KnownNat n
            => SNat n -> Signal dom (Unsigned (CLog 2 n))
countDown'' y = counter
    where start = snatToNum y
          counter = register (start - 1) (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1

countDown''' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n)
             => (1 <= n)
             => SNat n -> Signal dom (Unsigned (CLog 2 n))
countDown''' _ = counter
    where start = fromInteger $ snatToInteger (SNat @n)
          counter = register (start - 1) (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1

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

-- Create a Top Entity for Simulation
topEntity :: "CLK" ::: Clock System
          -> "IN"  ::: Signal System Bit
          -> "OUT" ::: Signal System Bit
topEntity clk = withClockResetEnable clk resetGen enableGen circuit
    where circuit inp = debounce (SNat @5) 0 inp 

makeTopEntity 'topEntity
