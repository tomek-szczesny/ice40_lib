// A generic clock divider
// by Tomek Szczesny 2022
//
//
//            +------------------+
//            |                  |
//            |                  |
// clk_in --->|      clkdiv      |---> clk_out
//            |                  |
//            |                  |
//            +------------------+
//
// clkdiv divides the frequency of input clock signal by "divider".
// "divider" is rounded up to nearest even integer.
// The output signal duty cycle is always 50%.
//
module clkdiv(
	input wire clk_in,
	output reg clk_out
);
parameter divider = 1000;

reg [$clog2((divider/2)+1):0] clkdiv;

always@(posedge clk_in)
begin
	if (clkdiv >= (divider/2)) begin
		clkdiv <= 0;
		clk_out <= ~clk_out;
	end else begin
		clkdiv <= clkdiv + 1;
	end
end

endmodule
