`include "fifo.v"
`include "sim.v"

module top(
);

reg clk = 0;
reg cke = 0;
reg clk_o = 0;
reg cke_o = 0;
reg [7:0] data;
wire [7:0] data_o;
wire [1:0] status;

always @ *
begin
	#5 clk <= ~clk;
end

integer i = 0;
initial
begin

#1	for (i=0; i<=530; i=i+1)
	begin
		data <= i;
#10 		cke <= 1; cke_o <= 0;
#10 		cke <= 0; cke_o <= 0;
	end

#100 	cke <= 0; cke_o <= 1;
#1	for (i=0; i<=530; i=i+1)
	begin
#10     data <= 0;
	end
#200
	$finish;
end

always @ (posedge clk, negedge clk, posedge clk_o, negedge clk_o) begin
	if (i < 10 || i > 500) #1 $display("clk: %b, cke: %b, cke_o: %b, data: %d, data_o: %d, status: %b, beq: %b, beq_m: %b, buf_t: %b, buf_b: %b", clk, cke, cke_o, data, data_o, status, MUT.beq, MUT.beq_m, MUT.buf_t, MUT.buf_b);
end

fifo_8   MUT (
	.clk(clk),
	.cke(cke),
	.data(data),
	.data_o(data_o),
	.clk_o(clk),
	.cke_o(cke_o),
	.status(status));

endmodule

