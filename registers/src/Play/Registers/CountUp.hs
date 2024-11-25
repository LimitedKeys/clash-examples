
module Play.Registers.CountUp where

import Clash.Prelude

-- Simple Example, Count up to 2^4
countUp :: HiddenClockResetEnable dom => Signal dom (Unsigned 4)
countUp = register 0 (countUp + 1)

-- Simple counter that counts up to the provided threshold
countUp' :: HiddenClockResetEnable dom => Unsigned 4 -> Signal dom (Unsigned 4)
countUp' threshold = counter
    where counter = register 0 (goUp <$> counter)
          goUp v = if v == threshold then 0 else v + 1

topEntity :: Clock System
          -> Reset System
          -> Enable System
          -> Signal System (Unsigned 4)
topEntity = exposeClockResetEnable $ countUp' 10

{-# OPAQUE topEntity #-}

{-# ANN topEntity
    (Synthesize
        { t_name = "countUp"
        , t_inputs = [ PortName "CLK"
                     , PortName "RST"
                     , PortName "EN"
                     ]
        , t_output = PortName "DATA"
        }
    ) #-}
