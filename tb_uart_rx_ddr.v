
// NOTE: This TB is supposed to run with ddr_input_fake.

`include "uart_rx.v"

module top(
);

reg in = 1;
reg clk = 0;
wire [7:0] out;
wire clk_out;

reg [21:0] data = 22'b1111010100010101110101;

initial
begin
$display("NOTE: This TB is supposed to run with ddr_input_fake.");
$display("The first byte: %b", data[9:2]);
$display("The second byte: %b", data[19:12]);
#10000 $finish;
end


always
begin
	#100 clk <= ~clk;
	$display("in: %d, clk: %d, out: %b, out_clk: %b, state: %b, osc: %b, ib: %b, arb: %b, offset: %b", in, clk, out, clk_out, MUT.state, MUT.osc, MUT.ib, MUT.arb, MUT.offset);
end

integer ict = 0;
always
begin
#1	in <= data[ict];
#387	ict = ict + 1;	// 3% error
end

uart_rx_ddr #(4) MUT (
	.in(in),
	.clk(clk),
	.out(out),
	.clk_out(clk_out));

endmodule

module ddr_in_fake (
	input wire clk,
	input wire pin,
	output reg [1:0] data
);

always @ (posedge clk) data[0] <= pin;
always @ (negedge clk) data[1] <= pin;

endmodule
