`include "johnson.v"

module top(
);

reg clk_in = 0;
reg rst = 0;
parameter width = 4;
wire [width-1:0] out;

initial
begin
$display ("Johnson Counter of size %d", width);
#98 rst <= 1; $display ("Reset asserted");
#35 rst <= 0; $display ("Reset cleared");
#200 $finish;
end


always
begin
	#5 clk_in <= ~clk_in;
	#5 $display ("in: %d, rst: %d, out: %b", clk_in, rst, out);
end


johnson #(
	.n(width))
	MUT (
	.clk(clk_in),
	.clr(rst),
	.out(out));


endmodule

