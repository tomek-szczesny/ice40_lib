// Greyscale dither algorithms 
// by Tomek Szczęsny 2024
//
// This file provides combinatorial logic handling math behind various dither
// algorithms. These algorithms generally reduce color palette while
// distributing quantization error, in order to improve perceived image quality.
//
// There are two general classes for dither algorithms.
// 
// Patterning dither algorithms use predefined 2D maps to help decide on 
// the direction of rounding, as pixel data lose their precision.
// Dither maps can be either in form of LUTs or combinational logic.
// These algorithms only require pixel values and coordinates,
// operate independently of other pixels, thus can be easily paralleled.
// Examples include Blue Noise dither and Ordered (Bayer Matrix).
//
// Error diffusion algorithms attempt to spread quantization error to
// neighboring pixels, avoiding modification of already processed ones.
// These algorithms must be applied to pixels in predefined, sequential order,
// and produce error data that must be stored. Error data may be generated
// even two rows ahead, which requires relatively substantial amounts of memory.
// Most notable examples include Floyd-Steinberg and Atkinson. 
//
// References: 
// 1. https://en.wikipedia.org/wiki/Dither#Algorithms
// 2. https://surma.dev/things/ditherpunk/


`ifndef _dither_v_
`define _dither_v_

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// ordered_mono
// A specific implementation generating monochromatic output based on
// greyscale input. 
//
//                          +------------------+
//                in[n] ===>|                  |---> out
//                 x[m] ===>|   ordered_mono   |
//                 y[m] ===>|                  |
//                          +------------------+
//
// Parameters:
// n - bit size of input data, must not be larger than Bayer matrix datum (8)
// m - clog2 of the Bayer Matrix edge size (4)
//
// Ports:
// in	- Pixel value input
// x	- Pixel X coordinate (supply LSBs if too large)
// y	- Pixel Y coordinate (supply LSBs if too large)
// out	- Monochromatic pixel output
//
module ordered_mono (
	input wire [n-1:0] in,
	input wire [m-1:0] x,
	input wire [m-1:0] y,
	output reg out
);

parameter n = 8;
parameter m = 4;

localparam bdw = (m*2);		// Bayer Matrix datum width

wire [bdw-1:0] bo;
wire [bdw-1:0] in_x;
assign in_x = in << (bdw - n);


bayer #(m) matrix (
	.x(x),
	.y(y),
	.o(bo)
);

always @ (in_x, bo)
begin
	if 	(in_x == 0) out <= 0;
	else if (in_x == (2**n-1)) out <= 1;
	else     out <= (in_x > bo);
end

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// blue_mono
// Monochromatic variant of Blue Noise dither.
// Uses precalculated blue noise maps.
// Requires pixel clock to operate internal ROM (synthesized as RAM blocks).
// Textures sourced from:
// https://github.com/Calinou/free-blue-noise-textures/blob/master/16_16/HDR_L_0.png
// https://github.com/Calinou/free-blue-noise-textures/blob/master/32_32/HDR_L_0.png
// https://github.com/Calinou/free-blue-noise-textures/blob/master/64_64/HDR_L_0.png
// Note: Textures have been flattened to 8-bit depth.
//
//                          +-----------------+
//                in[8] ===>|                 |---> out
//                 x[n] ===>|    blue_mono    |
//                 y[n] ===>|                 |
//                   clk--->|                 |
//                          +-----------------+
//
// Parameters:
// map	- Select blue noise map. Larger maps use more resources, especially RAM
// 	  blocks. Available sizes: 16, 32, 64. (16)
// 
// Local Params:
// n	- Pixel coordinate input width, depends on blue noise map size.
//
// Ports:
// in	- Pixel value input, pad narrower values towards MSB
// x	- Pixel X coordinate (LSBs)
// y	- Pixel Y coordinate (LSBs)
// clk  - Pixel clock, posedge latches input data
// out	- Monochromatic pixel output
//
module blue_mono (
	input wire [7:0] in,
	input wire [n-1:0] x,
	input wire [n-1:0] y,
	input wire clk,
	output reg out
);

parameter map = 16;
localparam n = $clog2(map);

reg [7:0] bn;

// Generating noise map ROM
// due to limitations of Verilog, filename cannot be a module param
// Thus ROM submodule cannot be used here.
reg [7:0] rom [0:(map*map)-1];

initial begin
	if (map == 16) $readmemh("assets/bn16.mem", rom);
	if (map == 32) $readmemh("assets/bn32.mem", rom);
	if (map == 64) $readmemh("assets/bn64.mem", rom);
end

always @ (posedge clk)
begin
	bn <= rom[{x,y}];
end

always @ *
begin
	if (in < 4) out <= 0;
	else if (in > 251) out <= 1;
	else out <= (in > bn);
end
//assign out = (in > bn);

endmodule

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// Bayer Matrix
// https://en.wikipedia.org/wiki/Ordered_dithering
//
// Asynchronously returns a matrix value, without use of LUT
// Values are 0 based unsigned integers.
//
// Parameters:
// n		- Matrix size, matrix edge is 2**n (4)
//
// Ports:
// x		- X coordinate of matrix element (zero based, left to right)
// y		- Y coordinate of matrix element (zero based, top to bottom)
// o[(n+1)*2]	- Matrix element value

module bayer(
	input wire [n-1:0] x,
	input wire [n-1:0] y,
	output wire [n*2-1:0] o
);

parameter n = 4;

genvar i;
generate
	for (i = 0; i < n; i = i + 1) begin
		assign o[(i*2)]   = y[n-i-1]; 
		assign o[(i*2)+1] = x[n-i-1] ^ y[n-i-1]; 
	end
endgenerate

endmodule

`endif
