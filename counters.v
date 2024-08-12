`ifndef _counters_v_
`define _counters_v_

////////////////////////////////////////////////////////////////////////////////
module ctr_pr4(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 4;
localparam lut_data = 16'b0000001011111101;

wire lo;

SB_LUT4 lut (
	.O(lo),
	.I0(out[0]),
	.I1(out[1]),
	.I2(out[2]),
	.I3(out[3])
);
defparam lut.LUT_INIT = lut_data;

always @ (posedge clk)
begin
	if (inc) begin
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo;
	end
end

endmodule

////////////////////////////////////////////////////////////////////////////////
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

////////////////////////////////////////////////////////////////////////////////
module ctr_pr6(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 6;
localparam lut_data1 = 16'b0000111100101101;
localparam lut_data2 = 16'b0000111100101101;

wire lo1, lo2;

SB_LUT4 lut1 (
	.O(lo1),
	.I0(out[0]),
	.I1(out[1]),
	.I2(out[2]),
	.I3(out[4])
);
SB_LUT4 lut2 (
	.O(lo2),
	.I0(out[2]),
	.I1(out[3]),
	.I2(out[5]),
	.I3(lo1)
);
defparam lut1.LUT_INIT = lut_data1;
defparam lut2.LUT_INIT = lut_data2;

always @ (posedge clk)
begin
	if (inc) begin
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo2;
	end
end

endmodule

////////////////////////////////////////////////////////////////////////////////
module ctr_pr7(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 7;
localparam lut_data = 16'b1100001101001011;

wire lo;
reg msb = 1'b0;

SB_LUT4 lut (
	.O(lo),
	.I0(out[0]),
	.I1(out[3]),
	.I2(out[6]),
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

////////////////////////////////////////////////////////////////////////////////
module ctr_pr8(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 8;
localparam lut_data1 = 16'b0100101111000011;
localparam lut_data2 = 16'b0100101111000011;

wire lo1, lo2;
reg msb = 1'b0;

SB_LUT4 lut1 (
	.O(lo1),
	.I0(out[0]),
	.I1(out[1]),
	.I2(out[4]),
	.I3(msb)
);
SB_LUT4 lut2 (
	.O(lo2),
	.I0(out[1]),
	.I1(out[4]),
	.I2(out[7]),
	.I3(lo1)
);
defparam lut1.LUT_INIT = lut_data1;
defparam lut2.LUT_INIT = lut_data2;

always @ (posedge clk)
begin
	if (inc) begin
		msb <= out[n-1];
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo2;
	end
end

endmodule

////////////////////////////////////////////////////////////////////////////////
module ctr_pr9(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 9;
localparam lut_data1 = 16'b0011001101100011;
localparam lut_data2 = 16'b0011001101100011;

wire lo1, lo2;
reg msb = 1'b0;

SB_LUT4 lut1 (
	.O(lo1),
	.I0(out[2]),
	.I1(out[3]),
	.I2(out[6]),
	.I3(out[7])
);
SB_LUT4 lut2 (
	.O(lo2),
	.I0(out[0]),
	.I1(out[8]),
	.I2(msb),
	.I3(lo1)
);
defparam lut1.LUT_INIT = lut_data1;
defparam lut2.LUT_INIT = lut_data2;

always @ (posedge clk)
begin
	if (inc) begin
		msb <= out[n-1];
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo2;
	end
end

endmodule

////////////////////////////////////////////////////////////////////////////////
module ctr_pr10(
	input wire clk,
	input wire inc,
	output reg [n-1:0] out = 0);

localparam n = 10;
localparam lut_data1 = 16'b0100101111000011;
localparam lut_data2 = 16'b0100101111000011;

wire lo1, lo2;
reg msb = 1'b0;

SB_LUT4 lut1 (
	.O(lo1),
	.I0(out[0]),
	.I1(out[4]),
	.I2(out[5]),
	.I3(msb)
);
SB_LUT4 lut2 (
	.O(lo2),
	.I0(out[0]),
	.I1(out[5]),
	.I2(out[9]),
	.I3(lo1)
);
defparam lut1.LUT_INIT = lut_data1;
defparam lut2.LUT_INIT = lut_data2;

always @ (posedge clk)
begin
	if (inc) begin
		msb <= out[n-1];
		out [n-1:1] <= out[n-2:0];
		out[0] <= lo2;
	end
end

endmodule





`endif
