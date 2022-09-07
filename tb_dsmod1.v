`include "dsmod1.v"

module top(
);

reg  clk = 0;
reg  signed [n-1:0] data = 0;
reg  clr = 0;
wire out;
parameter n = 4;

initial
begin
	$display ("Input bit depth: %d", n);
	#2 clr <= 1;
	#5 clr <= 0;
	     data <= 7;
	#100 data <= -8;
	#100 data <= 0;
	#100 data <= 3;
	#100 $finish;
end


always
begin
	#5 clk <= 1;
	#5 clk <= 0;
	$display ("in: %d, out: %d", data, out);
end


dsmod1 #(
	.n(n))
	MUT (
	.in(data),
	.out(out),
	.clk(clk),
	.clr(clr));


endmodule

