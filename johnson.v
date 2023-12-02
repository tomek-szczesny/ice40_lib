// n-bit Johnson counter
// by Tomek Szczęsny 2023
//
// Implements a Johnson counter of any width (>= 2).
// Complete with an asynchronous reset input.
//
// Example output of 3-bit counter:
// 000
// 001
// 011
// 111
// 110
// 100
//
//
//             +------------------+
//             |                  |
//     clk --->|     johnson      |===> out[n]
//     clr --->|                  |
//             +------------------+
//
// Parameters:
// n	- Bit width of an output, must be greater than 1 (8)
//
// Ports:
// clk	- input clock
// clr  - asynchronous reset input ("clear"), active high
// out	- a Johnson counter output
//
`ifndef _johnson_v_
`define _johnson_v_

module johnson(
	input wire clk,
	input wire clr,
	output reg [n-1:0] out);
parameter n = 8;

initial out = 0;
genvar i;

always @(posedge clk, posedge clr)
begin
	if (clr == 1) begin
		out <= 0;
	end else begin
		out[0] <= ~out[n-1];
		out[n-1:1] <= out[n-2:0];
	end
end

endmodule

`endif
