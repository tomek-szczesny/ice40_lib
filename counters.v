`ifndef _counters_v_
`define _counters_v_

///////
module ctr_pr4(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 4;
localparam lut_data = 16'b0100101100101001;

wire lo;
reg msb = 0;

SB_LUT4 lut (
	.O(lo),
	.I0(out[0]),
	.I1(out[1]),
	.I2(out[3]),
	.I3(msb)
);
defparam lut.LUT_INIT = lut_data;

always @ (posedge clk)
begin
	if (inc) begin
		msb <= out[n-1];
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo;
	end
end

endmodule

///////
module ctr_pr5(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 5;
localparam lut_data = 16'b1100001101001011;

wire lo;
reg [1:0] msb = 2'b00;

SB_LUT4 lut (
	.O(lo),
	.I0(out[0]),
	.I1(out[1]),
	.I2(out[4]),
	.I3(msb[1])
);
defparam lut.LUT_INIT = lut_data;

always @ (posedge clk)
begin
	if (inc) begin
		msb <= {msb[0], out[n-1]};
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo;
	end
end

endmodule


`endif
