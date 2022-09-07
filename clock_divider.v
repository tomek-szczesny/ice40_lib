//
// A generic clock divider
// by Tomek Szczesny 2022
//
// clkdiv divides the frequency of input clock signal by "divider".
// "divider" is rounded down to the nearest even integer.
// The output signal duty cycle is always 50%.
//
//            +------------------+
//            |                  |
//     in --->|      clkdiv      |---> out
//            |                  |
//            +------------------+
//
// Parameters:
// divider - a clock divider. Rounded down to the nearest even integer.
//
// Ports: 
// in	- Input
// out	- Output
//
module clkdiv(
	input wire in,
	output reg out = 0
);
parameter divider = 2;

reg [$clog2((divider/2)+1):0] clkdiv = 0;

always@(posedge in)
begin
	if (clkdiv >= (divider/2)) begin
		clkdiv <= 1;
		out <= ~out;
	end else begin
		clkdiv <= clkdiv + 1;
	end
end

endmodule
