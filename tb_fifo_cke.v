`include "fifo.v"

module top(
);

reg clk = 0;
reg cke = 0;
reg clk_o = 0;
reg cke_o = 0;
reg [3:0] data;
wire [3:0] data_o;
wire [3:0] status;

always @ *
begin
	#5 clk <= ~clk;
end

initial
begin
	data <= 4;
#35 	cke <= 1; cke_o <= 0;
#20 	cke <= 0; cke_o <= 0;
	data <= 2;
#35 	cke <= 1; cke_o <= 0;
#40 	cke <= 0; cke_o <= 0;
	data <= 1;
#35 	cke <= 1; cke_o <= 0;
#160 	cke <= 0; cke_o <= 1;
#200
	$finish;
end

always @ (posedge clk, negedge clk, posedge clk_o, negedge clk_o) begin
	#1 $display("clk: %b, cke: %b, cke_o: %b, data: %d, data_o: %d, status: %b", clk, cke, cke_o, data, data_o, status);
end

fifo_cke #(
	.m(16),
	.n(4))
	MUT (
	.clk(clk),
	.cke(cke),
	.data(data),
	.data_o(data_o),
	.clk_o(clk),
	.cke_o(cke_o),
	.status(status));

endmodule

