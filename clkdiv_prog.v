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
// The reset output can be used to inhibit clock consumer for the
// duration of the transition.
// For this reason, one full clock cycle with an old setting is propagated
// with reset output high.
//
//            +------------------+
//            |                  |---> reset
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
// reset 	- Asserted when div != latched div value
//
`ifndef _clkdiv_prog_v_
`define _clkdiv_prog_v_
`include "clkgate.v"

module clkdiv_prog(
	input wire in,
	input wire [n-1:0] div,
	output wire reset,
	output wire out
);
parameter n = 4;

reg [n-1:0] clkdiv = 0;		// Divider counter
reg [n-1:0] seldiv = 0;		// Selected divider ratio
reg outb = 0;			// Output buffer
wire ing;			// Gated input
reg [1:0] state = 0;		// State register

// Reset output
assign reset = |state;


always@(posedge in)
begin
	if (clkdiv <= 1) begin		// Advance clkdiv
		case (state)
			2'b00:  begin
				clkdiv <= seldiv;
				if (div != seldiv) state <= 2'b01;
				end
			2'b01:  begin
				clkdiv <= div;
				seldiv <= div;
				state <= 2'b11;
				end
			2'b11:  begin
				clkdiv <= seldiv;
				state <= 2'b10;
				end
			2'b10:  begin
				clkdiv <= seldiv;
				state <= 2'b00;
				end
		endcase
	
	end else begin
		clkdiv <= clkdiv - 1;
	end
					// Produce output
	outb <= (clkdiv > (seldiv >> 1));
end
// Handling a special case of div == 1
// A gated clock passthrough
clkgate clkgate (
	.in(in),
	.gate(seldiv == 1),
	.out(ing)
);
assign out = (seldiv == 1) ? ing : outb; 


endmodule

`endif
