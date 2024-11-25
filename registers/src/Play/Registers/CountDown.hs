
module Play.Registers.CountDown where

import Clash.Prelude

countDown :: forall a dom. (HiddenClockResetEnable dom)
          => (Eq a, NFDataX a, Num a)
          => a -> Signal dom a
countDown start = counter
    where counter = register start (goDown <$> counter)
          goDown 0 = start
          goDown i = i - 1

countDown' :: forall n dom. (HiddenClockResetEnable dom)
           => KnownNat n
           => SNat n -> Signal dom (Unsigned n)
countDown' _ = counter
    where start = snatToNum (SNat @n)
          counter = register start (goDown <$> counter)
          goDown 0 = start
          goDown x = x - 1

countDown'' :: forall n dom. (HiddenClockResetEnable dom)
            => (1 <= n)
            => KnownNat n
            => SNat n -> Signal dom (Unsigned (CLog 2 n))
countDown'' _ = counter
    where start = snatToNum (SNat @n)
          counter = register (start - 1) (goDown <$> counter)
          goDown 0 = start
          goDown x = x - 1

topEntity :: Clock System
          -> Reset System
          -> Enable System
          -> Signal System (Unsigned 4)
topEntity = exposeClockResetEnable $ countDown'' (SNat @10)

{-# ANN topEntity
    (Synthesize
        { t_name = "countDown"
        , t_inputs = [ PortName "CLK"
                     , PortName "RST"
                     , PortName "EN"
                     ]
        , t_output = PortName "DATA"
        }
    ) #-}
