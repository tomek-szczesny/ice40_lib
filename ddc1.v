// 1-bit Digital-to-Digital Converter
// by Tomek Szczęsny 2022
//
// Returns an n-bit signed number, saturated at max or min,
// depending on the binary input.
//
//             +------------------+
//             |                  |
//      in --->|       ddc1       |===> out[n]
//             |                  |
//             +------------------+
//
// Parameters:
// n	- Bit width of output, must be greater than 1 (16)
//
// Ports:
// in	- input value	
// out	- an output signed number
//
`ifndef _ddc1_v_
`define _ddc1_v_

module ddc1(
	input wire in,
	output wire signed [n-1:0] out);
parameter n = 16;

genvar i;
generate
	for (i=0; i<n-1; i=i+1) begin
		assign out[i] = in;
	end
	assign out[n-1] = ~in;
endgenerate

endmodule

`endif
