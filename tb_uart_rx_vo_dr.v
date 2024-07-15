`include "uart_rx.v"

module top(
);

reg in = 1;
reg [3:0] o;
reg clk = 0;
wire [7:0] out;
wire dr;
reg dr_rst = 0;

reg [22:0] data = 23'b11110101000111101110101;
reg [22:0] drrd = 23'b11100101000000000000001;

initial
begin
$display("The first byte: %b", data[9:2]);
$display("The second byte: %b", data[20:13]);
#44000 $finish;
end


always
begin
	#100 clk <= ~clk;
	$display("in: %d, clk: %d, out: %b, dr: %b, dr_rst: %b, o: %b", in, clk, out, dr, dr_rst, o);
end

integer ict = 0;
always
begin
#1	in <= data[ict];
	dr_rst <= drrd[ict];
	if (ict < 11)
	begin
#999		ict = ict + 1;
		o <= 5;
	end else begin
#1599		ict = ict + 1;
		o <= 8;
	end
end

uart_rx_vo_dr #(4) MUT (
	.in(in),
	.clk(clk),
	.o(o),
	.out(out),
	.dr(dr),
	.dr_rst(dr_rst)
);

endmodule

