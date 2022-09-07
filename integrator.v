// Generic integrator
// by Tomek Szczęsny 2022
//
//
// Digital integrator adds each "in" value to "out" register on "clk" posedge.
// This integrator works with signed integers.
// The overflow behavior is currently unspecified.
//
//                +------------------+
//        clk --->|                  |
//        clr --->|                  |
//                |    integrator    |
//      in[n] ===>|                  |===> out[m]
//                +------------------+
//
// Parameters:
// n - bit size of input wire (16)
// m - bit size of output reg, must be greater or equal to "n" (17)
//
// Signals:
// clk - input clock. Each posedge fetches "in" and updates "out".
// clr - asynchronously resets "out" register to zero.
// in[n] - input data
// out[n+m] - output data

module integrator (
	input wire clk,
	input wire clr,
	input wire signed [n-1:0] in,
	output reg signed [m-1:0] out
);

parameter n = 16;
parameter m = 17;

always @ (posedge clk)
begin
	if (clr == 1)
	begin
		out <= 0;
	end else begin
		out <= out + in;
	end
end

endmodule

