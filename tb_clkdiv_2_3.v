`include "clkdiv.v"

module top(
);

reg  clk_in = 0;
reg  sel= 0;
wire clk_out;
wire reset;

initial
begin
	sel <= 0;
#44
	sel <= 1;
#44
	sel <= 0;
#44
	sel <= 1;
#44
	sel <= 0;
#44 $finish;
end


always
begin
	#5 clk_in <= ~clk_in;
	$display ("in: %d, sel: %d, out: %d", clk_in, sel, clk_out);
end


clkdiv_2_3 #(
	)
	MUT (
	.in(clk_in),
	.sel(sel),
	.out(clk_out));


endmodule

