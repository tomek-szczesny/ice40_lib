`include "clkgate.v"

module top(
);

reg  clk_in = 0;
reg  clk_gate = 0;
wire clk_out;

initial
begin
#37 $finish;
end

always
begin
	#1 $display ("in: %d\t gate: %d\t out: %d", clk_in, clk_gate, clk_out);
end

always
begin
	#3 clk_in <= ~clk_in;
end

always
begin
	#5 clk_gate <= ~clk_gate;
end

clkgate
	MUT (
	.in(clk_in),
	.gate(clk_gate),
	.out(clk_out)
);

endmodule

