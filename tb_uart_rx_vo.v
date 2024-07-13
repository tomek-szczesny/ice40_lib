`include "uart_rx.v"

module top(
);

reg in = 1;
reg [3:0] o;
reg clk = 0;
wire [7:0] out;
wire clk_out;

reg [22:0] data = 23'b11110101000111101110101;

initial
begin
$display("The first byte: %b", data[9:2]);
$display("The second byte: %b", data[20:13]);
#44000 $finish;
end


always
begin
	#100 clk <= ~clk;
	$display("in: %d, clk: %d, out: %b, out_clk: %b, o: %b", in, clk, out, clk_out, o);
end

integer ict = 0;
always
begin
#1	in <= data[ict];
	if (ict < 11)
	begin
#999		ict = ict + 1;
		o <= 5;
	end else begin
#1599		ict = ict + 1;
		o <= 8;
	end
end

uart_rx_vo #(4) MUT (
	.in(in),
	.clk(clk),
	.o(o),
	.out(out),
	.clk_out(clk_out));

endmodule

