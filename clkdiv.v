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
	output reg out
);
parameter divider = 31;

reg [$clog2(divider)-1:0] clkdiv = 0;

always@(posedge in)
begin
	if (clkdiv == 0) begin
		clkdiv <= divider - 1;
	end else begin
		clkdiv <= clkdiv - 1;
	end
	out <= clkdiv < (divider/2);
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
// A high performance clock divider, by 2 or 5
// by Tomek Szczesny 2024
//
// clkdiv_2_5 divides the frequency of input clock signal by either 2 or 5,
// depending on the polarity of input signal.
// Its primary application is early stages of frequency division.
//
// This divider transitions with no glitches.
// The output signal duty cycle is near 50% if the input duty cycle is also 50%.
// In and out posedges are in sync.
//
//            +----------------+
//    sel --->|                |
//     in --->|   clkdiv_2_5   |---> out
//            |                |
//            +----------------+
//
// Parameters:
// None.
//
// Ports: 
// sel	- Division select (2 when low, 5 when high)
// in	- Input
// out	- Output
//

module clkdiv_2_5(
	input wire sel,
	input wire in,
	output wire out
);

reg [2:0] ne = 0;
reg pe = 0;

always@(negedge in)
begin
	if (ne == 3'b000) ne <= sel ? 3'b001 : 3'b100;
	if (ne == 3'b001) ne <= sel ? 3'b110 : 3'b100;
	if (ne == 3'b011) ne <= sel ? 3'b100 : 3'b100;
	if (ne == 3'b010) ne <= sel ? 3'b100 : 3'b100;
	if (ne == 3'b110) ne <= sel ? 3'b111 : 3'b000;
	if (ne == 3'b111) ne <= sel ? 3'b100 : 3'b000;
	if (ne == 3'b101) ne <= sel ? 3'b000 : 3'b000;
	if (ne == 3'b100) ne <= sel ? 3'b000 : 3'b000;
end

always@(posedge in)
begin
	pe <= ne[2];
end

assign out = pe && (ne[2] || ~sel);

endmodule

//
// Maximally optimized programmable divider
// by powers of 2, up to 128
// by Tomek Szczesny 2024
//
// clkdiv_2n divides the frequency of input clock signal by a power of 2,
// in range 2-128.
// Setting divisor below 2 results in division by 2.
//
// This divider must be reset to transition without a glitch.
// If glitches are acceptable, reset is not necessary.
// The output signal duty cycle is at 50%.
// In and out posedges are in sync.
//
//     d2 --->+----------------+
//     d4 --->|                |
//    d16 --->|   clkdiv_2n    |---> out
//     in --->|                |
//    rst --->+----------------+
//
// Parameters:
// None.
//
// Ports: 
// d2	- Adds one division by 2 to the total divisor
// d4	- Adds one division by 4 to the total divisor
// d16	- Adds one division by 16 to the total divisor
// in	- Input
// out	- Output
// rst	- Active high synchronous reset
//
/*
function carry (input a, b, c);
	carry = (a&&b) || (a&&c) || (b&&c);	// 0 + młodsze carry + młodszy bit
endfunction

module clkdiv_2n(
	input wire d2,
	input wire d4,
	input wire d16,
	input wire rst,
	input wire in,
	output wire out
);

reg [6:0] div = 0;
assign out = div[6];

always@(posedge in)
begin
	if (rst) div <= 0;
	else begin
		div[3:0] <= div[3:0] + 1;
		div[4] <= carry (0, div[3], &div[2:0]);
		div[6] <= div[4];
	end
end

endmodule
*/

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
// compact version, without div1 handling
// by Tomek Szczesny 2024
//
// clkdiv_prog divides the frequency of the input clock signal by a selected
// divider ratio.
//
// The divider ratio is selected with a binary number on div input.
// The divider ratio is being read on each out posedge.
// Glitches are avoided, but sometimes it may have to cycle through the full
// capacity of 'div' input.
//
// The output signal duty cycle is as near 50% as possible (sometimes more).
// In and out posedges are in sync.
//
// div == 0 causes out <= 1, effectively disabling the output.
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
parameter n = 11;

reg [n-1:0] clkdiv = 1;		// Divider counter
wire [n-1:0] clkdivm1;
assign clkdivm1 = clkdiv - 1;

always@(posedge in)
begin
	if (clkdiv == 1) begin
		clkdiv <= div;
		out <= 1;
	end
	else begin
		clkdiv <= clkdivm1;
		if (clkdivm1 == div[n-1:1]) out <= 0;
	end
end

endmodule

`endif
