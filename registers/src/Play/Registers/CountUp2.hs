
module Play.Registers.CountUp2 where

import Clash.Prelude

-- Count up to 2^n using an SNAT
countUp'' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => SNat n -> Signal dom (Unsigned n)
countUp'' _ = s
    where s = register 0 (s + 1)

-- Count up to (Threshold - 1)
--
-- log2 4 = 2, which can represent 0, 1, 2, and 3
--
-- Requires ScopedTypeVariables to pass `n` to the internal SNat. This extension
-- requies that `n` be declared in the `forall` statement.
--
-- Also requires the constraint (1 <= n) since CLog can't work with values lower
-- than 1.
countUp''' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) 
           => (1 <= n)
           => SNat n -> Signal dom (Unsigned (CLog 2 n))
countUp''' _ = counter
    where counter = register 0 (goUp <$> counter)
          threshold = snatToNum (SNat @n) - 1
          goUp v = if v < threshold then v + 1 else 0

topEntity :: Clock System
          -> Reset System
          -> Enable System
          -> Signal System (Unsigned 4)
topEntity = exposeClockResetEnable $ countUp''' (SNat @10)

{-# OPAQUE topEntity #-}

{-# ANN topEntity
    (Synthesize
        { t_name = "countUp2"
        , t_inputs = [ PortName "CLK"
                     , PortName "RST"
                     , PortName "EN"
                     ]
        , t_output = PortName "DATA"
        }
    ) #-}
