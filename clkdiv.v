//
// A generic clock divider
// by Tomek Szczesny 2022
//
// clkdiv divides the frequency of input clock signal by "divider".
// The output signal duty cycle is as near 50% as possible (sometimes less).
// In and out posedges are in sync.
//
//            +------------------+
//            |                  |
//     in --->|      clkdiv      |---> out
//            |                  |
//            +------------------+
//
// Parameters:
// divider - a clock divider.
//
// Ports: 
// in	- Input
// out	- Output
//
`ifndef _clkdiv_v_
`define _clkdiv_v_

module clkdiv(
	input wire in,
	output reg out = 0
);
parameter divider = 2;

reg [$clog2(divider-1):0] clkdiv = 0;

always@(posedge in)
begin
	if (clkdiv >= (divider - 1)) begin
		clkdiv <= 0;
		out <= 1;
	end else begin
		clkdiv <= clkdiv + 1;
		out <= (clkdiv + 1 < (divider/2));
	end
end

endmodule


//
// A high performance clock divider, by 2 or 3
// by Tomek Szczesny 2024
//
// clkdiv_2_3 divides the frequency of input clock signal by either 2 or 3,
// depending on the polarity of input signal.
// Its primary application is early stages of frequency division.
//
// This divider transitions with no glitches.
// The output signal duty cycle is near 50% if the input duty cycle is also 50%.
// In and out posedges are in sync.
//
//            +----------------+
//    sel --->|                |
//     in --->|   clkdiv_2_3   |---> out
//            |                |
//            +----------------+
//
// Parameters:
// None.
//
// Ports: 
// sel	- Division select (2 when low, 3 when high)
// in	- Input
// out	- Output
//

module clkdiv_2_3(
	input wire sel,
	input wire in,
	output wire out
);

reg [1:0] ne = 0;
reg pe = 0;
reg rsel = 0;

always@(negedge in)
begin
	if (ne == 2'b00) 
	begin
		rsel <= sel;
		ne <= {sel, 1'b1};
	end
	if (ne == 2'b01) ne <= 2'b00;
	if (ne == 2'b11) ne <= 2'b01;
	if (ne == 2'b10) ne <= 2'b00;
end

always@(posedge in)
begin
	pe <= ne[0];
end

assign out = pe && (ne[0] || ~rsel);

endmodule


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

//
// A Programmable clock divider
// compact version, without div1 handling or div ratio latch
// by Tomek Szczesny 2024
//
// clkdiv_prog divides the frequency of the input clock signal by a selected
// divider ratio.
//
// The divider ratio is selected with a binary number on div input.
// The divider ratio is being read on each out posedge.
// Glitches are limited but not completely avoided. No extra pulses will be
// generated.
//
// The output signal duty cycle is as near 50% as possible (sometimes less).
// In and out posedges are in sync.
//
// div == 0 causes out <= 0, effectively disabling the output.
// div == 1 causes the gates of hell to open with an echoing squeak.
//
//
//            +-----------------+
//            |                 |
//     in --->|  clkdiv_prog_l  |---> out
// div[n] --->|                 |
//            +-----------------+
//
// Parameters:
// n		- div width in bits
//
// Ports: 
// in		- Input
// div[n-1:0]	- Divider ratio selection vector
// out		- Output
//
module clkdiv_prog_l(
	input wire in,
	input wire [n-1:0] div,
	output reg out
);
parameter n = 4;

reg [n-1:0] clkdiv = 1;		// Divider counter

always@(posedge in)
begin
	if (clkdiv == 1) begin
		out <= 1;
		clkdiv <= div;
	end 
	else begin
		clkdiv <= clkdiv - 1;
		out <= ((clkdiv-1 > (div >> 1)) && out);
	end
end

endmodule

`endif
