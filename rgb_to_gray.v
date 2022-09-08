// RGB to Grayscale Converter
// by Tomek Szczęsny 2022
//
// This converter uses CIE1931 formula with conveniently rounded coefficients:
// Y = (3/16 R)   + (12/16 G)  + (1/16 B)
// Or, in higher fidelity variant (2, default):
// Y = (7/32 R)   + (23/32 G)  + (2/32 B)
// In extreme variant (3) which is not recommended as it's barely better than #2:
// Y = (27/128 R) + (92/128 G) + (9/128 B)
//
//                +-------------------+
//       r[n] ===>|                   |
//       g[n] ===>|    rgb_to_gray    |===> y[m]
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

module rgb_to_gray (
	input wire [n-1:0] r,
	input wire [n-1:0] g,
	input wire [n-1:0] b,
	output wire [m-1:0] y);

parameter n = 8;
parameter m = 8;
parameter fidelity = 2;

if (fidelity == 1) begin
	wire [n+4:0] out;
	assign out = b + r + (r << 1) + (g << 2) + (g << 3);
	assign y = out[n+4:n+4-m];
end
if (fidelity == 2) begin
	wire [n+5:0] out;
	assign out = r + g + (r << 1) + (g << 1) + (b << 1) + (r << 2) + (g << 2) + (g << 4);
	assign y = out[n+5:n+5-m];
end
if (fidelity == 3) begin
	wire [n+7:0] out;
	assign out = r + b + (r << 1) + (g << 2) + (r << 3) + (g << 3) + (b << 3) + (r << 4) + (g << 4) + (g << 6);
	assign y = out[n+7:n+7-m];
end

endmodule

`endif
