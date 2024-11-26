
module Play.Blackbox.Counter where

import Data.String.Interpolate

import Clash.Prelude
import Clash.Annotations.Primitive

counter :: Clock System
        -> Reset System
        -> Enable System
        -> Unsigned 16 
        -> Signal System (Unsigned 16)
counter !_clk !_rst !_en !_thresh = deepErrorX "TODO: Define counter simulation output"

{-# OPAQUE counter #-}

-- Solution provided from Discourse (Thank you u/Imbollen)
{-# ANN counter (
    let
      funcName = 'counter -- Get the name of the counter function as a string
    in
      InlineYamlPrimitive [Verilog, SystemVerilog]
        [__i|
          BlackBox:
            kind: Declaration
            name: #{funcName}
            template: |
                counter \#(.THRESHOLD (~ARG[3])) ~GENSYM[counter][0] // Generate a unique name "counter" with index 0
                ( .DATA (~RESULT) // Connect the DATA output to the RESULT of counter
                , .CLK (~ARG[0]) // Connect the CLK input to the first argument of counter
                , .RST (~ARG[1]) // Connect the RST input to the second argument of counter
                , .EN (~ARG[2]) // Connect the EN input to the third argument of counter
                );
        |]) #-}

{-# ANN counter hasBlackBox #-}

top :: Clock System
    -> Reset System
    -> Enable System
    -> Signal System (Unsigned 16)
top clk rst en = counter clk rst en 10 + counter clk rst en 12

{-# ANN top 
   (Synthesize
    { t_name = "myCounter"
    , t_inputs = [ PortName "CLK"
                 , PortName "RST"
                 , PortName "EN"
                 ]
    , t_output = PortName "DATA"
    }) #-}
