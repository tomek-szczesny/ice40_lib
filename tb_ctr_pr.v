`include "counters.v"
`include "sim.v"

module top(
);

reg clk_in = 0;
wire [3:0] out4;
wire [4:0] out5;

initial
begin
#500	$finish;
end

always
begin
	#5 clk_in <= ~clk_in;
	if (~clk_in) $display ("clk: %b, out4: %b (%d)\t out5: %b (%d)", clk_in, out4, out4, out5, out5);
end

ctr_pr4 MUT4 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out4));

ctr_pr5 MUT5 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out5));

endmodule

