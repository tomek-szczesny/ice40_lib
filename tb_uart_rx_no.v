`include "uart_rx.v"

module top(
);

reg in = 1;
reg clk = 1;
wire [7:0] out;
wire clk_out;

reg [32:0] data = 33'b111010101010111110111011011111111;

initial
begin
$display("Transmitted byte #1: %b", data[16:9]);
$display("Transmitted byte #2: %b", data[28:21]);
#20000 $finish;
$display("Transmitted byte #1: %b", data[16:9]);
$display("Transmitted byte #2: %b", data[28:21]);
end


always
begin
	#100 clk <= ~clk;
	$display("in: %d, clk: %d, out: %b, out_clk: %b", in, clk, out, clk_out);
end

integer ict = 0;
always
begin
#1	in <= data[ict];
#199	ict = ict + 1;
end

uart_rx_no  MUT (
	.in(in),
	.clk(clk),
	.out(out),
	.clk_out(clk_out));

endmodule

