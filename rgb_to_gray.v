// RGB to Grayscale Converters
// by Tomek Szczęsny 2022, 2024
//
// A collection of converters, using different formulae.
//
// rgb_g_cie1931:
//
// This converter uses CIE1931 formula with conveniently rounded coefficients.
// Three precision variants exist:
// 1. Y = (3/16 R)   + (12/16 G)  + (1/16 B)
// 2. Y = (7/32 R)   + (23/32 G)  + (2/32 B)
// 3. Y = (27/128 R) + (92/128 G) + (9/128 B)
//
// rgb_g_ntsc:
// Using NTSC formula.
// Again three precision variants:
// 1: Y = (5/16 R)   + (9/16 G)   + (2/16 B)
// 2: Y = (19/64 R)  + (38/64 G)  + (7/64 B)
// 3: Y = (38/128 R) + (75/128 G) + (15/128 B)
//
//                +-------------------+
//       r[n] ===>|                   |
//       g[n] ===>|    rgb_g_xxxxx    |===> y[m]
//       b[n] ===>|                   |
//                +-------------------+
//
// Parameters:
// n - bit size of input wires (8)
// m - bit size of output wire. Must be lower than (n+4). (8)
// fidelity - valid options: 1, 2, 3. (2)
//
// Ports:
// r[n]	- red channel input
// g[n] - green channel input
// b[n] - blue channel input
// y[m]	- output in grayscale
//
`ifndef _rgb_to_gray_v_
`define _rgb_to_gray_v_

module rgb_g_cie1931 (
	input wire [n-1:0] r,
	input wire [n-1:0] g,
	input wire [n-1:0] b,
	output wire [m-1:0] y);

parameter n = 8;
parameter m = 8;
parameter fidelity = 2;

if (fidelity == 1) begin
	wire [n+3:0] out;
	assign out = b + r + (r << 1) + (g << 2) + (g << 3);
	assign y = out[n+3:n+4-m];
end
if (fidelity == 2) begin
	wire [n+4:0] out;
	assign out = r + g + (r << 1) + (g << 1) + (b << 1) + (r << 2) + (g << 2) + (g << 4);
	assign y = out[n+4:n+5-m];
end
if (fidelity == 3) begin
	wire [n+6:0] out;
	assign out = r + b + (r << 1) + (g << 2) + (r << 3) + (g << 3) + (b << 3) + (r << 4) + (g << 4) + (g << 6);
	assign y = out[n+6:n+7-m];
end

endmodule

// - - - - - - -

module rgb_g_ntsc (
	input wire [n-1:0] r,
	input wire [n-1:0] g,
	input wire [n-1:0] b,
	output wire [m-1:0] y);

parameter n = 8;
parameter m = 8;
parameter fidelity = 2;

if (fidelity == 1) begin
	wire [n+3:0] out;
	assign out = r + (r << 2) + g + (g << 3) + (b << 1);
	assign y = out[n+3:n+4-m];
end
if (fidelity == 2) begin
	wire [n+5:0] out;
	assign out = r + (r << 1) + (r << 4) + (g << 1) + (g << 2) + (g << 5) + b + (b << 1) + (b << 2);
	assign y = out[n+5:n+6-m];
end
if (fidelity == 3) begin
	wire [n+6:0] out;
	assign out = (r << 1) + (r << 2) + (r << 5) + g + (g << 1) + (g << 3) + (g << 6) + b + (b << 1) + (b << 2) + (b << 3);
	assign y = out[n+6:n+7-m];
end

endmodule

`endif
