//
// A generic clock divider
// by Tomek Szczesny 2022
//
// clkdiv divides the frequency of input clock signal by "divider".
// "divider" is rounded up to nearest even integer.
// The output signal duty cycle is always 50%.
//
//            +------------------+
//            |                  |
//     in --->|      clkdiv      |---> out
//            |                  |
//            +------------------+
//
// Parameters:
// divider - a clock divider
//
// Ports: 
// in	- Input
// out	- Output
//
module clkdiv(
	input wire in,
	output reg out
);
parameter divider = 1000;

reg [$clog2((divider/2)+1):0] clkdiv;

always@(posedge in)
begin
	if (clkdiv >= (divider/2)) begin
		clkdiv <= 0;
		out <= ~out;
	end else begin
		clkdiv <= clkdiv + 1;
	end
end

endmodule
