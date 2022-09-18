`include "uart_rx.v"

module top(
);

reg in = 1;
reg clk = 0;
wire [7:0] out;
wire clk_out;

reg [10:0] data = 11'b11101110110;

initial
begin

#20000 $finish;
end


always
begin
	#100 clk <= ~clk;
	$display("in: %d, clk: %d, out: %b, out_clk: %b", in, clk, out, clk_out);
end

integer ict = 0;
always
begin
#999	if (ict < 10) begin
		ict = ict + 1;
	end else begin
		ict = 0;
	end

#1	in <= data[ict];
end

uart_rx #(5) MUT (
	.in(in),
	.clk(clk),
	.out(out),
	.clk_out(clk_out));

endmodule

