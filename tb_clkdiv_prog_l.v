`include "clkdiv.v"

module top(
);

reg  clk_in = 0;
reg  [3:0] div = 0;
wire clk_out;

initial
begin
	div <= 0;
#80
	div <= 1;
#80
	div <= 2;
#120
	div <= 7;
#160
	div <= 2;
#200
	div <= 4;
#80
	div <= 0;
#80 $finish;
end


always
begin
	#5 clk_in <= ~clk_in;
	$display ("in: %d, div: %02d, out: %d", clk_in, div, clk_out);
end


clkdiv_prog_l #(
	.n(4))
	MUT (
	.in(clk_in),
	.div(div),
	.out(clk_out));


endmodule

