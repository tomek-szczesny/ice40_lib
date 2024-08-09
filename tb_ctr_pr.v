`include "primitives.v"
`include "sim.v"

module top(
);

reg clk_in = 0;
parameter width = 4;
//reg [14:0] reactor = 15'b000001001001011;
reg [14:0] reactor = 1;
reg [3:0] loop_ref;

initial
begin
$display ("Pseudo Random Counter of size %d", width);
end

integer c = 0;
integer i = 0;
initial
begin
	while (reactor != 0)
	begin
		c = 0;
		for (i=0; i<38; i=i+1)
		begin
			#5 clk_in <= ~clk_in;
			#5 clk_in <= ~clk_in;
		end
		loop_ref = out[3:0];
		c = 0;
		#5 clk_in <= ~clk_in;
		#5 clk_in <= ~clk_in;
		while (out[3:0] != loop_ref)
		begin
			c = c + 1;
			#5 clk_in <= ~clk_in;
			#5 clk_in <= ~clk_in;
		end
		if (c == 16) 
		begin
			$display ("c: %d, reactor: %b", c, reactor);
			for (i=0; i<18; i=i+1)
			begin
				#5 clk_in <= ~clk_in;
				#5 clk_in <= ~clk_in;
			$display ("out: %b (%3d), reactor: %b", out, out, reactor);
			end
		end

		
		#5 reactor = reactor + 1;
	
	end
	$finish;
end

wire lo;
pseudolut dalut ({reactor, 1'b1}, {out[4:3], out[1:0]}, lo);


reg [4:0] out = 0;
always @ (posedge clk_in)
begin
	out[4:1] <= out[3:0];
	out[0] <= lo;
end


/*
ctr_pr #(
	.n(width),
	.lut_data({15'd3734, 1'b1}))
	MUT (
	.clk(clk_in),
	.inc(1'b1),
	.out(out));
*/

endmodule

module pseudolut(
	input wire [15:0] lut,
	input wire [3:0] inputs,
	output wire out);

assign out = lut[inputs];

endmodule
