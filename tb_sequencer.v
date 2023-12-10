`include "sequencer.v"
`include "fifo.v"

module top(
);

reg clk = 0;
reg clk_f = 0;
wire [4:0] addr;
reg [4:0] data_f = 0;
reg jump = 0;
wire [8:0] data_o;
wire [4:0] pc;
wire stop;
wire [3:0] status_f;

initial
begin
	// Filling FIFO with function calls
	#30 data_f <= 2; #1 clk_f <= 1; #1 clk_f <= 0; 
	#1 data_f <= 12; #1 clk_f <= 1; #1 clk_f <= 0; 
	#1 data_f <= 19; #1 clk_f <= 1; #1 clk_f <= 0; 
	#1 data_f <= 25; #1 clk_f <= 1; #1 clk_f <= 0; 

	#500 data_f <= 2; #1 clk_f <= 1; #1 clk_f <= 0; 

	#100 $finish;
end

always	#5 clk <= ~clk;
always @ (posedge clk) begin
	#1 $display("clk: %d\taddr: %d\tjump: %d\tdata_o: %b\tpc: %d\tstop:%d", clk, addr, status_f[0], data_o, pc, stop);
end

sequencer #(
	.ocw(12),	// cccnnnnndddd
	.ddw(4),
	.plen(31),
	.std(256),
	.program({
		`SEQ_STOP, 5'd0, 4'b0000,	// 00 - this one will always be ignored
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_OUT, 5'd2, 4'b1001,	// 02
		`SEQ_OUT, 5'd2, 4'b1100,
		`SEQ_RET, 5'd2, 4'b0110,	// acts like OUT if stack empty
		`SEQ_OUT, 5'd2, 4'b0011,
		`SEQ_STOP, 5'd18, 4'b1001,
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_STOP, 5'd0, 4'b0000,	// Leave some space for future changes
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_OUT, 5'd4, 4'b1001,	// 12
		`SEQ_OUT, 5'd4, 4'b0011,
		`SEQ_RET, 5'd4, 4'b0110,
		`SEQ_OUT, 5'd4, 4'b1100,
		`SEQ_STOP, 5'd20, 4'b1001,
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_PUSHI, 5'd3, 4'b0000,	// 19: Push "3" to stack
		`SEQ_CALL, 5'd3, 4'b1001,	// 20: Call "3"	
		`SEQ_DECJNZ,5'd20,4'b0011,	// 21: Return here, go to 20 or 22
		`SEQ_OUT, 5'd2, 4'b1001,
		`SEQ_STOP, 5'd24, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,	////
		`SEQ_PUSHI, 5'd3, 4'b0000,	// 25: Push "3" to stack
		`SEQ_CALL, 5'd13, 4'b1001,	
		`SEQ_DECJNZ,5'd26,4'b1100,
		`SEQ_JMP, 5'd3, 4'b1001,
		`SEQ_STOP, 5'd24, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000	////
		})

)MUT (
	.clk(clk),
	.addr(addr),
	.jump(status_f[0]),
	.data_o(data_o),
	.pc(pc),
	.stop(stop));

fifo #(
	.m(256),
	.n(12-4-3)
) seq_fifo (
	.clk(clk_f),
	.data(data_f),
	.data_o(addr),
	.clk_o(~stop),
	.status(status_f));

endmodule

