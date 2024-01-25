// Block RAM configured as ROM
// by Tomek Szczęsny 2023
//
// Uses iCE40 4kb RAM blocks. For the best resuts, set ROM width and depth
// so the total capacity is a multiple of 4096b.
//
// As mentioned in ICE40 docs, the first memory address cannot be initialized. 
// To mitigate this issue, address "0" pints at a separate LUT-based reg.
//
// The ROM contents are to be defined as "data" parameter. For backward
// compatibility with Verilog (as opposed to SystemVerilog), it is represented
// as a binary vector. Here is an example of tiny 4x3 ROM, where each address
// contains itself. 
// data = {3'b0, 3'b1, 3'b2, 3'b3};
//
// Because of how Verilog works, if less data is being stored than the
// size of ROM, the "content_size" parameter must be defined, in order to
// assure correct data padding. See tb_rom.v for an example.
//
//
//                +----------------+
//        clk --->|                |
//                |       ROM      |              
// address[a] ===>|                |===> data_o[n]
//                |  (m * n bits)  |
//                |                |
//                +----------------+
//                             
//
// Parameters: 
//
// n			- ROM bit width. 2, 4, 8, 16. (8)
// m			- ROM depth (number of words) (512)
// data[n*m-1:0]	- input data vector (all zeroes)
// content_size		- number of words actually stored in ROM (m)
//
// Ports:
// clk		- a clock input. Posedge stores "data[n]".
// address[a] 	- ROM address input ("a" = clog2(m) )
// data_o[n]	- An output exposing the oldest data stored in FIFO
//
// Note:
// The "n" parameter may actually be any value, but be mindful of the ice40
// RAM block design and possible unusable memory. 
// Certainly n=10 and m=2048 is possible and will glue five 4k blocks together.

`ifndef _rom_v_
`define _rom_v_

module rom(
	input wire clk,
	input wire[$clog2(m)-1:0] address,
	output wire[n-1:0] data_o
);
parameter n = 8;
parameter m = 512;
parameter content_size = m;
parameter [0:n*m-1] data = 0;
localparam offset = m - content_size;

reg [n-1:0] rom [0:m-1];
genvar i;
generate
	for (i=1; i<content_size; i=i+1) begin
		initial rom[i] = data[n*(i+offset):n*(i+1+offset)-1];
	end
endgenerate

// separate register for address 0, which cannot be initialized in HW
reg [n-1:0] rom0;
initial rom0 = data[n*(offset):n*(1+offset)-1];

reg [n-1:0] brout;	// Block RAM output
reg az;			// Address Zero
assign data_o = az ? rom0 : brout;

// Data output
always @(posedge clk)
begin
	brout <= rom[address];
	az <= (address == 0);
end

endmodule

`endif
