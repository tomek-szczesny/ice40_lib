`include "rgb_to_gray.v"

module top(
);

reg  [7:0] r = 0;
reg  [7:0] g = 0;
reg  [7:0] b = 0;
wire [7:0] y;

initial
begin
#10	r = 000;	g = 000;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 055;	g = 055;	b = 055;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 255;	g = 255;	b = 255;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 255;	g = 000;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 000;	g = 255;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 000;	g = 000;	b = 255;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
$finish;
end

rgb_to_gray #(
	.m(8),
	.n(8),
	.fidelity(2))
	MUT (
	.r(r),
	.g(g),
	.b(b),
	.y(y));

endmodule

