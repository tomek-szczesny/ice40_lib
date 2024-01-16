`include "rgb_to_gray.v"

module top(
);

reg  [7:0] r = 0;
reg  [7:0] g = 0;
reg  [7:0] b = 0;
wire [7:0] y, z;

initial
begin
	$display ("CIE1931, fidelity 3");
#10	r = 000;	g = 000;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 055;	g = 055;	b = 055;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 255;	g = 255;	b = 255;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 255;	g = 000;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 000;	g = 255;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
#10	r = 000;	g = 000;	b = 255;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, y);
	$display ("NTSC, fidelity 3");
#10	r = 000;	g = 000;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, z);
#10	r = 055;	g = 055;	b = 055;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, z);
#10	r = 255;	g = 255;	b = 255;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, z);
#10	r = 255;	g = 000;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, z);
#10	r = 000;	g = 255;	b = 000;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, z);
#10	r = 000;	g = 000;	b = 255;	#1 $display("r=%d g=%d b=%d y=%d", r, g, b, z);
$finish;
end

rgb_g_cie1931 #(
	.m(8),
	.n(8),
	.fidelity(3))
	MUT (
	.r(r),
	.g(g),
	.b(b),
	.y(y));

rgb_g_ntsc #(
	.m(8),
	.n(8),
	.fidelity(3))
	MUT2 (
	.r(r),
	.g(g),
	.b(b),
	.y(z));
endmodule

