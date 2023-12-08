// Block RAM configured as ROM
// by Tomek Szczęsny 2023
//
// Uses iCE40 4kb RAM blocks. For the best resuts, set buffer width and depth
// so the total capacity is a multiple of 4096b.
//
// As mentioned in ICE40 docs, the first memory address "0" cannot be initialized. 
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
// m			- ROM depth (512)
// data[n*m-1:0]	- input data vector 
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
parameter [n*m-1:0] data = 0;

reg [n-1:0] rom [0:m-1];
initial rom = data;

reg  [$clog2(m):0] buf_a = 0;
assign data_o = rom[buf_a];

// Data output
always @(posedge clk_o)
begin
	buf_a <= address;

endmodule

`endif
