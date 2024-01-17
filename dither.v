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
// Uses precalculated 16x16 map found in ./assets/bluenoise16.data.
// Requires pixel clock to operate internal ROM.
// Texture sourced from:
// https://github.com/Calinou/free-blue-noise-textures/blob/master/16_16/HDR_L_0.png
//
//                          +-----------------+
//                in[8] ===>|                 |---> out
//                 x[4] ===>|    blue_mono    |
//                 y[4] ===>|                 |
//                   clk--->|                 |
//                          +-----------------+
//
// Parameters:
// None
//
// Ports:
// in	- Pixel value input, pad narrower values towards MSB
// x	- Pixel X coordinate (LSBs)
// y	- Pixel Y coordinate (LSBs)
// clk  - Pixel clock, posedge latches input data
// out	- Monochromatic pixel output
//
module blue16_mono (
	input wire [7:0] in,
	input wire [3:0] x,
	input wire [3:0] y,
	input wire clk,
	output reg out
);

reg [7:0] bn;

//TODO: First byte should be zero as it cannot be initialized in hardware.
localparam bluenoise16_pattern = {128'h6f318ea271c347b1c932975e422555fc, \
				128'h1963efde20fa9413266adcaac28a0da7,
				128'h7db24f0f41ad7b57d583f7177436e5d4,
				128'h29ca9884bd6835eca13e01b54df19344,
				128'h02f4385be605cc1cbb6590ce215cbe6b,
				128'hdfa47224d69c8b46f554e2307e9e1187,
				128'h53c415fe4c2db3730c28a969fdb0d33b,
				128'h64b4917aac61eb81d795c708481aee2c,
				128'he81f450bcd3a12c1583c70dd8c567899,
				128'hd082f3a0e06e22f8a518eab834c6ab06,
				128'h6cbc335989ba9a4e2f86629d23f95f3f,
				128'h104bdb270143e479c5f0034a7f14e38f,
				128'hf6af77c8fb67920ed1ae6ddac052cba3,
				128'h1d5d9616a6b6371e5a402a8da839752e,
				128'hd8e93d8051edd9769ffeb91bf2660485,
				128'h49bf09d22b600788e7500a7ce1cf9bb7
};

rom #(
	.m(256),
	.n(8),
	.data(bluenoise16_pattern),
	.content_size(256)
) bluerom (
	.clk(clk),
	.address({x,y}),
	.data_o(bn)
);

assign out = (in > bn);
/*
always @ (in, bn)
begin
	if 	(in == 0) out <= 0;
	else if (in == 255) out <= 1;
	else     out <= (in > bn);
end
*/
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
