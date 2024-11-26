
module counter(input CLK, input RST, input EN, output [15:0] DATA);

reg [15:0] iDATA;
initial iDATA = 0;

assign DATA = iDATA;

always @(posedge CLK)
  begin
    if (RST) 
      iDATA <= 0;
    else if (EN)
      begin
        iDATA <= iDATA + 1;
      end
  end

endmodule
