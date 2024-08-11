`include "counters.v"
`include "sim.v"

module top(
);

reg clk_in = 0;
wire [3:0] out4;
wire [4:0] out5;
wire [5:0] out6;
wire [6:0] out7;
wire [7:0] out8;

initial
begin
#2560	$finish;
end

always
begin
	#5 clk_in <= ~clk_in;
	if (~clk_in) $display ("clk: %b    out4: %b (%d)    out5: %b (%d)    out6: %b (%d)    out7: %b (%d)    out8: %b (%d)",
		clk_in, out4, out4, out5, out5, out6, out6, out7, out7, out8, out8);
	if (clk_in && out4 == 0) $display("===");
end

ctr_pr4 MUT4 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out4));

ctr_pr5 MUT5 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out5));

ctr_pr6 MUT6 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out6));

ctr_pr7 MUT7 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out7));

ctr_pr8 MUT8 (
	.clk(clk_in),
	.inc(1'b1),
	.out(out8));

endmodule

