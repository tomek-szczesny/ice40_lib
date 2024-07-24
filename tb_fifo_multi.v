`include "fifo.v"

module top(
);

reg clk = 0;
reg latch = 0;
reg [3:0] addr = 0;
reg [1:0] addr_o = 0;
reg [3:0] data;
wire [3:0] data_o;
wire [19:0] status;
wire rdy;

always @ *
begin
	#5 clk <= ~clk;
end

initial
begin
	data <= 4;
	addr <= 4'b0011;
	addr_o <= 3;
#35 	latch <= 1;
#20 	latch <= 0;
#100    addr  <= 4'b1111;
	data <= 2;
#35 	latch <= 1;
#20 	latch <= 0;
#100	data <= 1;
#35 	latch <= 1;
#20 	latch <= 0;
#30	addr_o <= 0;
#50	addr_o <= 1;
#50	addr_o <= 2;
#200
	$finish;
end

always @ (posedge clk, negedge clk) begin
	#1 $display("clk: %b, latch: %b, rdy: %b, data: %d, addr: %b, addr_o: %b data_o: %d, status: %b", clk, latch, rdy, data, addr, addr_o, data_o, status);
end

fifo_multi #(
	.m(16),
	.n(4),
	.o(4))
	MUT (
	.clk(clk),
	.latch(latch),
	.data(data),
	.data_o(data_o),
	.addr(addr),
	.rdy(rdy),
	.clk_o(clk),
	.addr_o(addr_o),
	.status(status));
//
//module fifo_multi(
//	input wire clk,
//	output wire rdy,
//	input wire[n-1:0] data,
//	input wire[o-1:0] addr,
//	input wire latch,
//	input wire clk_o,
//	output reg[n-1:0] data_o,
//	input wire[$clog2(o-1):0] addr_o,
//	output wire[w*o-1:0] status
//);
//parameter n = 8;	// Word width
//parameter m = 64;	// Word capacity of each subbuffer
//parameter o = 8;	// Number of subbuffers

endmodule

