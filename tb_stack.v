`include "stack.v"

module top(
);

reg clk = 0;
reg [2:0] cmd = 0;
reg [3:0] data = 0;
wire [3:0] data_o;
wire [3:0] status;

initial
begin	
	#20 data <= 1; cmd <= `STK_PUSH;
	#10 data <= 2; cmd <= `STK_PUSH;
	#10 data <= 3; cmd <= `STK_PUSH;
	#10 data <= 4; cmd <= `STK_PUSH;
	#10 data <= 5; cmd <= `STK_PUSH;
	#10 data <= 6; cmd <= `STK_PUSH;
	#10 data <= 7; cmd <= `STK_PUSH;
	#10 data <= 8; cmd <= `STK_PUSH;
	#10 data <= 9; cmd <= `STK_PUSH;
	#10 data <= 10; cmd <= `STK_PUSH;
	#10 data <= 10; cmd <= `STK_INC;
	#10 data <= 10; cmd <= `STK_INC;
	#10 data <= 10; cmd <= `STK_DEC;
	#10 data <= 10; cmd <= `STK_LDI;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_NOP;
	#10 data <= 10; cmd <= `STK_NOP;
	#10 data <= 10; cmd <= `STK_NOP;
	#10 data <= 10; cmd <= `STK_NOP;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_POP;
	#10 data <= 10; cmd <= `STK_POP;
	#30 $finish;
end

always	#5 clk <= ~clk;
always @ (clk) begin
	$display("clk: %d\tcmd: %b\tdata: %d\tdata_o: %d\tstatus: %b", clk, cmd, data, data_o, status);
end

stack #(
	.m(8),
	.n(4))
	MUT (
	.clk(clk),
	.data(data),
	.command(cmd),
	.data_o(data_o),
	.status(status));

endmodule

