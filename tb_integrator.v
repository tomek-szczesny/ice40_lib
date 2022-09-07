`include "integrator.v"

module top(
);

reg signed [7:0] in = 33;
wire signed [8:0] out;
reg clk = 0;
reg clr = 0;

initial
begin
#5  clr <= 1;
#10 clr <= 0;
#5  in[7:0] <= -7;
#20 $display ("Added %d, Output: %d", in, out);
in <= -122;
#20 $display ("Added %d, Output: %d", in, out);
in <= -122;
#20 $display ("Added %d, Output: %d", in, out);
in <= 75;
#20 $display ("Added %d, Output: %d", in, out);
in <= -75;
#20 $display ("Added %d, Output: %d", in, out);
in <= -14;
#20 $display ("Added %d, Output: %d (Note: intentional output overflow)", in, out);
clr <= 1;
#20 $display ("Cleared output, Output: %d", out);
$finish;
end


always
begin
	#10 clk = ~clk;
end


integrator #(
	.m(9),
	.n(8))
	MUT (
	.clk(clk),
	.clr(clr),
	.in(in),
	.out(out));


endmodule

