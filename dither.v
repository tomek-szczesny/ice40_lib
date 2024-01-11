// Monochromatic dither algorithms 
// by Tomek Szczęsny 2024
//
// This file provides combinatorial logic handling math behind various dither
// algorithms. These algorithms generally reduce color palette while spreading
// quantization error, in order to improve perceived image quality.
//
// No data storage is implemented and ought to be handled externally.
//
// References: 
// 1. https://en.wikipedia.org/wiki/Dither#Algorithms
//
//
// All modules handle input pixel datum of width (n),
// output pixel datum of width (m), and
// immediate error data as signed integers of size (n+1).
//
// Output pixel datum is a sum of input datum and cumulated error for the
// field a pixel is in.
// 
// Error outputs differ in number and directions across algorithms, so
// the following error output name convention has been adopted:
// n,s,e,w correspond to cardinal map directions.
// [ns] are mutually exclusive directions and come before [ew].
// Multiple [ns] or [ew] characters mean further distance in that direction.
//
// Some algorithms may require pixel coordinates given as "x" and "y".
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// floyd-steinberg
// TODO: atkinson based on this
//
//                +-------------------+
//      in[n] ===>|                   |===> out[m]
//   err[n+1] ===>|  floyd-steinberg  |===> e, sw, s, se [n-m+1]
//                |                   |
//                +-------------------+
//
// Parameters:
// n - bit size of input wire (8)
// m - bit size of output wire. Must be lower than n. (1)
//
// Ports:
// TODO (TBD)
//
`ifndef _dither_v_
`define _dither_v_

module floyd-steinberg (
	input wire [n-1:0] in,
	input wire signed [n:0] err,
	output wire [m-1:0] out,
	output wire signed [n-m:0] e,
	output wire signed [n-m:0] sw,
	output wire signed [n-m:0] s,
	output wire signed [n-m:0] se,
);

parameter n = 8;
parameter m = 1;

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


// Specialized round function
// - Unsigned input and output
// - Signed error output of appropriate size

module dt_round(
	input wire [n-1:0] in,
	output reg [m-1:0] out,
	output reg signed [n-m:0] err
);
parameter n = 8;
parameter m = 1;

localparam outmax = (2^^m) - 1;

always @ (in)
begin
	if (~in[n-m-1] or in[n-1:n-m] = outmax) begin	// round down, prevent overflow
		out <= in[n-1:n-m];
		err <= in[n-m-1:0];
	end else begin					// round up
		out <= in[n-1:n-m] + 1;
		err <= 0 - in[n-m-1:0];
	end
end
endmodule

`endif
