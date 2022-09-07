// First order Delta Sigma Modulator
// by Tomek Szczęsny 2022
//
// Transforms signed integers into a bit stream.
// 
//
//             +------------------------------+
//     clk --->|                              |
//     clr --->|                              |
//             |      dsmod1    +----------+  |---> out
//             |                |integrator|  |
//   in[n] ===>|                +----------+  |
//             +------------------------------+
//
// Parameters:
// n	- Bit width of input data (16)
//
// Ports:
// clk		- a sampling clock input. Oversampling is generally required.
// clr		- Asynchronous reset
// in[n]	- Input data, signed integers.
// out		- an output bit stream.
//
`include "integrator.v"

module dsmod1(
	input wire clk,
	input wire clr,
	input wire signed [n-1:0] in,
	output wire out);
parameter n = 16;

wire signed [n:0] i1_in;	// Integrator input
wire signed [n+1:0] i1_out;	// Integrator output
assign out = i1_out[n+1];
assign i1_in = in - ddc;

// DDC
wire signed [n-1:0] ddc;
genvar i;
generate
	for (i=0; i<n-1; i=i+1) begin
		assign ddc[i] = out;
	end
	assign ddc[n-1] = ~out;
endgenerate

integrator #(
	.n(n+1),
	.m(n+2)) i1 (
	.clk(clk),
	.clr(clr),
	.in(i1_in),
	.out(i1_out));

endmodule
