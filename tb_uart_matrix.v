`include "uart_matrix.v"

module top(
);

reg clk = 1;
reg [1:0] rx;
reg [2:0] lut_data;
reg [1:0] lut_addr;
reg lut_cke;

wire [7:0] tx;
wire [2:0] tx_cke;

reg [0:49] rx0    = 50'b11111111111011001100111110010101011111111111111111;
reg [0:49] rx1    = 50'b11111111111000110011111110101010101111111111111111;
reg [0:49] lt_cke = 50'b00001110000000000000001000000000000000000000000000;

initial
begin
	lut_data <= 3'b101;
	lut_addr <= 0;
#2000	lut_data <= 3'b011;
	lut_addr <= 1;
#30000	$finish;
end


always
begin
	#100 clk <= ~clk;
	$display("clk: %b, rx: %b, l_d: %b, l_a: %b, l_c: %b, tx: %b, tx_cke: %b", clk, rx, lut_data, lut_addr, lut_cke, tx, tx_cke);
end

integer ict = 0;
always
begin
#1	rx[0] = rx0[ict];
	rx[1] = rx1[ict];
	lut_cke = lt_cke[ict];
#199	ict = ict + 1;
end

uart_matrix #(2, 3) MUT (
	.clk(clk),
	.rx(rx),
	.lut_data(lut_data),
	.lut_addr(lut_addr),
	.lut_cke(lut_cke),
	.tx(tx),
	.tx_cke(tx_cke));

endmodule

