`include "clkdiv.v"

module top(
);

reg  clk_in = 0;
reg  [3:0] div = 0;
wire clk_out;
wire reset;

initial
begin
	div <= 0;
#80
	div <= 1;
#80
	div <= 2;
#120
	div <= 3;
#160
	div <= 4;
#200
	div <= 1;
#80
	div <= 0;
#80 $finish;
end


always
begin
	#5 clk_in <= ~clk_in;
	$display ("in: %d, div: %02d, out: %d, reset: %d", clk_in, div, clk_out, reset);
end


clkdiv_prog #(
	.n(4))
	MUT (
	.in(clk_in),
	.div(div),
	.reset(reset),
	.out(clk_out));


endmodule

