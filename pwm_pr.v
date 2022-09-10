// Pseudo-Random PWM modulator
// by Tomek Szczęsny 2022
//
// A slightly modified PWM modulator shifts the frequency spectrum of the
// output stream towards higher frequencies, which could be beneficial in
// audio-visual applications. The result arguably has similar benefits of
// delta-sigma modulators' output.
//
// It works by changing the order of PWM states being filled with ones, as
// the input value rises.
// In conventional PWM, that is (for period of 8):
// 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
//
// This modulator assumes the following pattern:
// 0 | 4 | 2 | 6 | 1 | 5 | 3 | 7 
//
// This modulator works only with periods being a power of 2.
// The input to output path is purely combinational, so it reacts instantly to
// input data changes. This structure may be reused in multiplexed
// input/output scenarios.
// The input data must be unsigned and of clog2(period) width.
//
//             +----------------+
//     clk --->|                |
//             |     pwm_pr     |---> out
//   in[n] ===>|                |
//             +----------------+
//
// Parameters:
// period	- a number of states to cycle through, must be a power of 2 (16)
//
// Ports:
// clk		- PWM clock input
// in[n]	- Input data, unsigned integer. "n" is fixed at clog2(period).
// out		- an output bit stream
//
`ifndef _pwm_pr_v_
`define _pwm_pr_v_

module pwm_pr(
	input wire clk,
	input wire [$clog2(period)-1:0] in,
	output wire out);
parameter period = 16;

reg [$clog2(period)-1:0] cnt = 0;
wire [$clog2(period)-1:0] mangled_cnt;

always @ (posedge clk) begin
		cnt <= cnt + 1;
end

genvar i;
generate
	for (i=0; i<$clog2(period); i=i+1) begin
		assign mangled_cnt[i] = cnt[$clog2(period)-1-i];
	end
endgenerate

assign out = (in > mangled_cnt) ? 1 : 0;

endmodule

`endif
