
module Play.Registers where

import Clash.Prelude

countUp :: HiddenClockResetEnable dom => Signal dom (Unsigned 4)
countUp = register 0 (countUp + 1)

countUp' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => Signal dom (Unsigned n)
countUp' = register 0 (countUp' + 1)

countUp'' :: forall n dom. (HiddenClockResetEnable dom, KnownNat n) => SNat n -> Signal dom (Unsigned n)
countUp'' _ = s
    where s = register 0 (s + 1)
