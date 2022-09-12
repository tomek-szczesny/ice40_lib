// Generic integrator
// by Tomek Szczęsny 2022
//
// Digital integrator adds each "in" value to "out" register on "clk" posedge.
// This integrator works with signed integers. Output register may be wider
// than input register.
// The output register wraps on overflow (see testbench).
//
//                +------------------+
//        clk --->|                  |
//        clr --->|    integrator    |
//      in[n] ===>|                  |===> out[m]
//                +------------------+
//
// Parameters:
// n - bit size of input wire (16)
// m - bit size of output reg, must be greater or equal to "n" (17)
//
// Ports:
// clk		- input clock. Each posedge fetches "in" and updates "out".
// clr		- asynchronously resets "out" register to zero.
// in[n]	- input data
// out[m]	- output data
//
// Resources:
// m x SB_LUT
// m x SB_DFFR

`ifndef _integrator_v_
`define _integrator_v_

module integrator (
	input wire clk,
	input wire clr,
	input wire signed [n-1:0] in,
	output reg signed [m-1:0] out = 0
);

parameter n = 16;
parameter m = 17;

always @ (posedge clk, posedge clr)
begin
	if (clr == 1)
	begin
		out <= 0;
	end else begin
		out <= out + in;
	end
end

endmodule

`endif
