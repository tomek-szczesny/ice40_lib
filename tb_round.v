`include "round.v"

module top(
);

reg signed [4:0] in = 0;
wire signed [4:0] out;
wire signed [4:0] err;
integer i;

initial
begin
	for (i = -16; i < 16; i=i+1) begin
		in = i;
		#1 $display("in=%d out=%d err=%d; in=%b out=%b err=%b", in, out, err, in, out, err);
	end
	$finish;
end

round #(
	.m(5),
	.n(5),
	.p(2))
	MUT (
	.in(in),
	.out(out),
	.err(err));

endmodule

