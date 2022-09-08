// Second order Delta Sigma Modulator
// by Tomek Szczęsny 2022
//
// Transforms signed integers into a bit stream.
// Note: Since 2nd order modulators are not unconditionally stable,
// it may misbehave in certain circumstances.
//
//             +--------------------------------------------+
//     clk --->|                  +------+      +------+    |
//             |                  | ddc1 |      | ddc1 |    |
//     clr --->|                  +------+      +------+    |
//             |      dsmod2    +----------+  +----------+  |---> out
//             |                |integrator|  |integrator|  |
//   in[n] ===>|                +----------+  +----------+  |
//             +--------------------------------------------+
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

module dsmod2(
	input wire clk,
	input wire clr,
	input wire signed [n-1:0] in,
	output wire out);
parameter n = 16;

wire signed [n+1:0] i1_in;	// Integrator input
wire signed [n+2:0] i1_out;	// Integrator output
wire signed [n+3:0] i2_in;	// Integrator input
wire signed [n+4:0] i2_out;	// Integrator output
assign out = i2_out[n+4];
assign i1_in = in - ddc1;
assign i2_in = i1_out - ddc2;

// ddc1 and ddc2 are fed back to integrator inputs respectively
wire signed [n-1:0] ddc1;
wire signed [n+2:0] ddc2;
ddc1 #(
	.n(n)) ddc11 (
	.in(out),
	.out(ddc1));

ddc1 #(
	.n(n+3)) ddc12 (
	.in(out),
	.out(ddc2));

integrator #(
	.n(n+2),
	.m(n+3)) i1 (
	.clk(clk),
	.clr(clr),
	.in(i1_in),
	.out(i1_out));

integrator #(
	.n(n+4),
	.m(n+5)) i2 (
	.clk(clk),
	.clr(clr),
	.in(i2_in),
	.out(i2_out));
endmodule
