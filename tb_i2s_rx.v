`include "i2s_rx.v"

module top(
);

reg sck = 0;
reg ws = 0;
reg sd = 0;
wire [4:0] l;
wire [4:0] r;
wire ock;
parameter b = 5;

reg [7:0] data = 7'b01110110;

initial
begin

#450 $finish;
end


always
begin
	#5 sck <= ~sck;
end

integer wsi = 0;
integer i = 0;
always @ (negedge sck) begin
	if (wsi < 6) begin
		wsi = wsi + 1;
	end else begin
		wsi = 0;
		ws <= ~ws;
	end

	if (i < 7) begin
		i = i + 1;
	end else begin
		i = 0;
	end
	sd <= data[i];
end
always @ (posedge sck) begin
	#1 $display("ws: %d, sd: %d, l: %b, r: %b, ock: %b", ws, sd, l, r, ock);end

i2s_rx #(
	.b(b))
	MUT (
	.sck(sck),
	.ws(ws),
	.sd(sd),
	.l(l),
	.r(r),
	.ock(ock));

endmodule

