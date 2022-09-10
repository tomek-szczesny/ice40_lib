`include "pwm_pr.v"

module top(
);

reg  clk_in = 0;
reg [2:0] in = 3;
wire out;
parameter period = 8;

initial
begin
$display ("Input value: %d", in);
$display ("PWM period: %d", period);
#170 in <= 6; #1 $display ("Input value: %d", in);

#150 $finish;
end


always
begin
	#5 clk_in <= ~clk_in;
end

always
begin
	#10 $display ("out: %d", out);
end


pwm_pr #(
	.period(period))
	MUT (
	.clk(clk_in),
	.in(in),
	.out(out));

endmodule

