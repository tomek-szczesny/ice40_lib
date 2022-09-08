`include "clkdiv.v"

module top(
);

reg  clk_in = 0;
wire clk_out;
parameter clk_div = 6;

initial
begin
$display ("Clock divider: %d", clk_div);
#300 $finish;
end


always
begin
	#5 clk_in <= ~clk_in;
	#5 $display ("in: %d, out: %d", clk_in, clk_out);
end


clkdiv #(
	.divider(clk_div))
	MUT (
	.in(clk_in),
	.out(clk_out));


endmodule

