//
// Integer round
// by Tomek Szczesny 2022
//
//TODO: Solve the mystery of line #52 (assign out).
//
// This module rounds signed integers into the given bit precision.
// The output may have lower width than input, which effectively divides the
// number by 2^(n-m). This may be desirable if one is interested in just the
// significant bits of rounding.
//
// Additional error output provides difference between in and out (also signed).
// It does not account for reduced bit width of the output port.
//
//            +-----------------+
//  in[n] ===>|                 |===> out[m]
//            |      round      |        
//            |                 |===> err[n]
//            +-----------------+
//
// Parameters:
// n	- Bit width of "in" (8)
// m	- Bit width of "out" (m <= n)  (8)
// p	- Rounding precision (remaining significant bits) (p < n-1) (2)
//
// Ports: 
// in[n]	- Input signed integer
// out[m]	- Output signed integer, rounded, and with trimmed LSBs if requested
// err[n]	- Rounding error
//
`ifndef _round_v_
`define _round_v_

module round(
	input wire signed [n-1:0] in,
	output wire signed [m-1:0] out,
	output wire signed [n-1:0] err
);
parameter n = 8;
parameter m = 8;
parameter p = 2;

wire signed [n-1:0] rnd;	// input with added round-floor magic number
assign rnd[n-1:0] = in[n-1:0] + $pow(2, n-p-2);
wire signed [n-1:0] rnd2;	// rnd with zeroed out LSBs

// Overflow may happen - but only over the top
assign rnd2[n-1:n-p-1] = (rnd[n-1] == 1 && in[n-1] == 0) ? 
			(in[n-1:n-p-1]) : 
			(rnd[n-1:n-p-1]);
assign rnd2[n-p-2:0] = 0;
assign out = rnd2[n:n-m];    // No idea why this actually works - could be Icarus bug?
assign err = in - rnd2;

endmodule

`endif
