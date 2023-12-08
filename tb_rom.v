`include "rom.v"

module top(
);

reg clk = 0;
reg [2:0] add = 0;
wire [3:0] data_o;


initial
begin
	add <= 0;
	#100 $finish;
end

always 
begin
	#5 clk <= ~clk;
	$display("clk: %d, addr: %d, data_o: %d", clk, add, data_o);
end

always @ (posedge clk) add <= add + 1;

rom #(
	.m(8),
	.n(4),
	.data({4'd0,4'd1,4'b10,8'b00110100,4'd5}), // 0,1,2,3,4,5
	.content_size(6)
)
	MUT (
	.clk(clk),
	.address(add),
	.data_o(data_o)
);

endmodule

