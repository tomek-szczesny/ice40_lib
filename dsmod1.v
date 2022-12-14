// First order Delta Sigma Modulator
// by Tomek Szczęsny 2022
//
// Transforms signed integers into a bit stream.
// 
//
//             +-------------------------------+
//     clk --->|               +----------+    |
//     clr --->|               |integrator|    |---> out
//             |     dsmod1    +----------+    |
//             |               +-----+         |
//   in[n] ===>|               | ddc |         |
//             |               +-----+         |
//             +-------------------------------+
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
`ifndef _dsmod1_v_
`define _dsmod1_v_

`include "integrator.v"
`include "ddc1.v"

module dsmod1(
	input wire clk,
	input wire clr,
	input wire signed [n-1:0] in,
	output wire out);
parameter n = 16;

wire signed [n-1:0] ddc1;
wire signed [n:0] i1_in;	// Integrator input
assign i1_in = in - ddc1;
wire signed [n+1:0] i1_out;	// Integrator output
assign out = i1_out[n+1];

ddc1 #(
	.n(n)) ddc11 (
	.in(out),
	.out(ddc1));

integrator #(
	.n(n+1),
	.m(n+2)) i1 (
	.clk(clk),
	.clr(clr),
	.in(i1_in),
	.out(i1_out));

endmodule

`endif
