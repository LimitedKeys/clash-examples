
module Play.Registers where

import Clash.Prelude

countUp :: HiddenClockResetEnable dom => Signal dom (Unsigned 4)
countUp = register 0 (countUp + 1)

countUp' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => Signal dom (Unsigned n)
countUp' = register 0 (countUp' + 1)

countUp'' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => SNat n -> Signal dom (Unsigned n)
countUp'' _ = s
    where s = register 0 (s + 1)

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
          counter = register start (goDown <$> counter)
          goDown 0 = 0
          goDown x = x - 1

-- Take a signal dom a - if it changes from the "start" state, then start a
-- counter. After the counter is complete, take the value of the input and
-- return that?
debounce :: forall n a dom. (HiddenClockResetEnable dom)
         => KnownNat n
         => (NFDataX a, Eq a)
         => SNat n -> a -> Signal dom a -> Signal dom a
debounce _ current input_signal = undefined
