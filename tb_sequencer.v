`include "sequencer.v"

module top(
);

reg clk = 0;
reg [4:0] addr = 0;
reg jump = 0;
wire [8:0] data_o;
wire [4:0] pc;
wire stop;


initial
begin	
	#30 addr <= 2;
	#10 jump <= 1;
	#30 jump <= 0;
	#40 addr <= 12;
	#30 jump <= 1;
	#10 jump <= 0;
	#70 addr <= 19;
	#10 jump <= 1;
	#10 jump <= 0;
	#220 addr <= 25;
	#10 jump <= 1;
	#20 jump <= 0;
	#290 $finish;
end

always	#5 clk <= ~clk;
always @ (posedge clk) begin
	#1 $display("clk: %d\taddr: %d\tjump: %d\tdata_o: %b\tpc: %d\tstop:%d", clk, addr, jump, data_o, pc, stop);
end

sequencer #(
	.ocw(12),	// cccnnnnndddd
	.ddw(4),
	.plen(31),
	.std(256),
	.program({
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,	// 01
		`SEQ_OUT, 5'd2, 4'b1001,	// 02
		`SEQ_OUT, 5'd2, 4'b1100,
		`SEQ_RET, 5'd2, 4'b0110,	// acts like OUT if stack empty
		`SEQ_OUT, 5'd2, 4'b0011,
		`SEQ_OUT, 5'd2, 4'b1001,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,	// Leave some space for future changes
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_OUT, 5'd4, 4'b1001,	// 12
		`SEQ_OUT, 5'd4, 4'b0011,
		`SEQ_RET, 5'd4, 4'b0110,
		`SEQ_OUT, 5'd4, 4'b1100,
		`SEQ_OUT, 5'd4, 4'b1001,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,	
		`SEQ_PUSHI, 5'd5, 4'b0000,	// 19: Push "5" to stack
		`SEQ_CALL, 5'd3, 4'b1001,	// 20: Call "3"	
		`SEQ_DECJNZ,5'd20,4'b0011,	// 21: Return here, go to 20 or 22
		`SEQ_OUT, 5'd2, 4'b1001,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_PUSHI, 5'd5, 4'b0000,	// 25: Push "5" to stack
		`SEQ_CALL, 5'd13, 4'b1001,	
		`SEQ_DECJNZ,5'd26,4'b1100,
		`SEQ_JMP, 5'd3, 4'b1001,
		`SEQ_STOP, 5'd0, 4'b0000,
		`SEQ_STOP, 5'd0, 4'b0000
		})

)MUT (
	.clk(clk),
	.addr(addr),
	.jump(jump),
	.data_o(data_o),
	.pc(pc),
	.stop(stop));

endmodule

