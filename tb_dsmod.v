`include "dsmod1.v"
`include "dsmod2.v"

module top(
);

reg  clk = 0;
reg  signed [n-1:0] data = 0;
reg  clr = 0;
wire out1, out2;
parameter n = 4;

initial
begin
	$display ("Input bit depth: %d", n);
	#2 clr <= 1;
	#5 clr <= 0;
	     data <= 7;
	#200 data <= -8;
	#200 data <= 0;
	#200 data <= 3;
	#200 $finish;
end


always
begin
	#5 clk <= 1;
	#5 clk <= 0;
	$display ("in: %d, out1: %d, out2: %d", data, out1, out2);
end


dsmod1 #(
	.n(n))
	MUT1 (
	.in(data),
	.out(out1),
	.clk(clk),
	.clr(clr));

dsmod2 #(
	.n(n))
	MUT2 (
	.in(data),
	.out(out2),
	.clk(clk),
	.clr(clr));

endmodule

