`include "fifo.v"

module top(
);

reg clk = 0;
reg clk_o = 0;
reg [3:0] data;
wire [3:0] data_o;
wire [2:0] status;

initial
begin
	data <= 4;
	clk <= 0;
	clk_o <= 0;
	#1 $display("clk: %d, data: %d, data_o: %d, clk_o: %b, status: %b", clk, data, data_o, clk_o, status);
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 2;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 0;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 6;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 9;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 1;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 3;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 3;
	#5 clk <= 1;
	#5 clk <= 0;
	data <= 7;
	#5 clk <= 1;
	#5 clk <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	#5 clk_o <= 1;
	#5 clk_o <= 0;
	$finish;
end

always @ (posedge clk, negedge clk, posedge clk_o, negedge clk_o) begin
	#1 $display("clk: %d, data: %d, data_o: %d, clk_o: %b, status: %b", clk, data, data_o, clk_o, status);
end

fifo #(
	.m(8),
	.n(4))
	MUT (
	.clk(clk),
	.data(data),
	.data_o(data_o),
	.clk_o(clk_o),
	.status(status));

endmodule

