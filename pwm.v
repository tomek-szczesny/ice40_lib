// PWM modulator
// by Tomek Szczęsny 2022
//
// This modulator works with any integer period.
// The input to output path is purely combinational, so it reacts instantly to
// input data changes. This structure may be reused in multiplexed
// input/output scenarios.
// The input data must be unsigned and of clog2(period) width. Values above
// "period" will be treated as maximum.
//
//             +----------------+
//     clk --->|                |
//             |      pwm       |---> out
//   in[n] ===>|                |
//             +----------------+
//
// Parameters:
// period	- a number of PWM states to cycle through (16)
//
// Ports:
// clk		- PWM clock input
// in[n]	- Input data, unsigned integer. "n" is fixed at clog2(period).
// out		- an output bit stream
//
`ifndef _pwm_v_
`define _pwm_v_

module pwm(
	input wire clk,
	input wire [$clog2(period)-1:0] in,
	output wire out);
parameter period = 16;

reg [$clog2(period)-1:0] cnt = 0;

always @ (posedge clk) begin
	if (cnt < (period-1)) begin
		cnt <= cnt + 1;
	end else begin
		cnt <= 0;
	end
end

assign out = (in > cnt) ? 1 : 0;

endmodule

`endif
