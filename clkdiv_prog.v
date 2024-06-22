//
// A Programmable clock divider
// by Tomek Szczesny 2024
//
// clkdiv_prog divides the frequency of the input clock signal by a selected
// divider ratio.
//
// The divider ratio is selected with a binary number on div input.
// The divider ratio is updated on out posedge for glitchless transitions.
//
// The output signal duty cycle is as near 50% as possible (sometimes less).
// In and out posedges are in sync.
//
// div == 0 causes out <= 0, effectively disabling the output.
//
//            +------------------+
//            |                  |
//     in --->|   clkdiv_prog    |---> out
// div[n] --->|                  |
//            +------------------+
//
// Parameters:
// n		- div width in bits
//
// Ports: 
// in		- Input
// div[n-1:0]	- Divider ratio selection vector
// out		- Output
//
`ifndef _clkdiv_prog_v_
`define _clkdiv_prog_v_
`include "clkgate.v"

module clkdiv_prog(
	input wire in,
	input wire [n-1:0] div,
	output wire out
);
parameter n = 4;

reg [n-1:0] clkdiv = 0;		// Divider counter
reg [n-1:0] seldiv = 0;		// Selected divider ratio
reg outb = 0;			// Output buffer
wire ing;			// Gated input

// Handling a special case of div == 1
// A gated clock passthrough
clkgate clkgate (
	.in(in),
	.gate(seldiv == 1),
	.out(ing)
);

assign out = (seldiv == 1) ? ing : outb; 

always@(posedge in)
begin
	if (clkdiv <= 1) begin		// Advance clkdiv
		if (div == 0) begin
			clkdiv <= 0;
			seldiv <= 0;
		end else begin
			clkdiv <= div;
			seldiv <= div;
		end
	end else begin
		clkdiv <= clkdiv - 1;
	end
					// Produce output
	outb <= (clkdiv > (seldiv >> 1));
end

endmodule

`endif
