// Video test pattern generator
// by Tomek Szczęsny 2023
//
// Generates simple patterns, thus not requiring many FPGA resources.
// Generates one pixer per clock cycle, but can be slowed down through clock
// enable pin if the output buffer is full.
//
// Internal state may be reset to synchronize with video transmitter.
// 
// video_test_ddr can be found below, it generates 2 pixels at the same time.
//
//              +----------+                                + - - - - - 
//      clk --->|          |---> clk_o - - - - - - - clk - >|    
//      cke --->|   video  |                                   fifo
// pattern[2] =>|          |===> rd[r] \                    |
//              |   test   |===> gd[g]-  = = data[r+g+b] = >
//      rst --->|          |===> bd[b] /                    |
//              +----------+                                + - - - - - 
//                                                status[3]    |
//                                    (~cke)<- - - - - - - - - +
// Parameters: 
//
// v		- vertical image size (480)
// h		- horizontal image size (640)
// r,g,b	- bit width of each color channel (8)
//
// Ports:
// clk		- a clock input, active posedge
// cke 		- clock enable, logic high validates clk posedge
// pattern[2]	- Pattern selection, can change mid-frame.
// 		0: Green Screen
// 		1: single pixel b&w checkerboard
// 		2: "mctom"
// 		3: pseudorandom
// rst		- asynchronous internal state reset
// clk_o	- (clk & cke) output
// rd,gd,bd	- Parallel pixel outputs, for each color channel

`ifndef _video_test_v_
`define _video_test_v_
`include "clkgate.v"
`include "rom.v"

module video_test(
	input wire clk,
	input wire cke,
	input wire[1:0] pattern,
	input wire rst,
	output wire[r-1:0] rd,
	output wire[g-1:0] gd,
	output wire[b-1:0] bd,
	output wire clk_o
);
parameter v = 480;
parameter h = 640;
parameter r = 8;
parameter g = 8;
parameter b = 8;
localparam rmax = 2**r-1;
localparam gmax = 2**g-1;
localparam bmax = 2**b-1;

// Coordinate counters
reg [$clog2(v):0] vr = 0;
reg [$clog2(h):0] hr = 0;

// ROM data wire
wire [7:0] rom_data;

// Input clock gate
wire gclk;
assign clk_o = gclk;
clkgate vt_ckg (
	.in(clk),
	.gate(cke),
	.out(gclk)
);

always@(posedge gclk)
begin
	// coordinates counters
	if (rst) begin
		vr <= 0;
		hr <= 0;
	end else begin
		if (hr == h-1) begin
			hr <= 0;
			vr <= (vr == v-1) ? 0 : vr + 1;
		end else begin
			hr <= hr+1;
		end
	end

	// Actual pattern generation
		case (pattern)
			2'd0: begin
				rd <= 0;
				gd <= gmax;
				bd <= 0;
			end
			2'd1: begin
				if (vr[0] ^ hr[0]) begin
					rd <= rmax;
					gd <= gmax;
					bd <= bmax;
				end else begin
					rd <= 0;
					gd <= 0;
					bd <= 0;
				end
			end
			2'd2: begin
				if (rom_data[7-hr[2:0]]) begin
					rd <= rmax;
					gd <= gmax;
					bd <= bmax;
				end else begin
					rd <= 0;
					gd <= 0;
					bd <= 0;
				end
			end
			2'd3: begin
				rd <= hr[r-1:0] ^ vr[r-1:0];
				gd <= hr[g:1] ^ vr[g-1:0];
				bd <= hr[b-1:0] ^ vr[b:1];
			end
		endcase
end

// ROM with "mctom" bitmap
rom #(
	.m(32),
	.n(8),
	.data({8'h00,8'h00,8'h00,8'hfb,8'haa,8'h8b,8'h00,8'h00,8'h00,8'h10,8'h38,8'h93,8'h12,8'h93,8'h00,8'h00,8'h00,8'h00,8'h00,8'hbe,8'haa,8'ha2,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}),
	.content_size(32)
) vt_rom (
	.clk(~gclk),
	.address({hr[4:3],vr[2:0]}),
	.data_o(rom_data)
);

endmodule

//
// video_test_ddr
// Generates two pixels at the same time,
// which is useful with ddr-based drivers.
// all parameters and io remain the same, except 
// outputs "xd" are replaced with "xdo" and "xde",
// for odd and even pixel data, respectively.
// Notice that pixel positions starts with "0" which is even.

module video_test_ddr(
	input wire clk,
	input wire cke,
	input wire[1:0] pattern,
	input wire rst,
	output wire[r-1:0] rdo,
	output wire[g-1:0] gdo,
	output wire[b-1:0] bdo,
	output wire[r-1:0] rde,
	output wire[g-1:0] gde,
	output wire[b-1:0] bde,
	output wire clk_o
);
parameter v = 480;
parameter h = 640;
parameter r = 8;
parameter g = 8;
parameter b = 8;
localparam rmax = 2**r-1;
localparam gmax = 2**g-1;
localparam bmax = 2**b-1;

// Coordinate counters
reg [$clog2(v):0] vr = 0;
reg [$clog2(h):0] hr = 0;
wire [$clog2(h):0] hrp1;
assign hrp1 = hr | 1'b1;	// hr plus one; hr is always even

// ROM data wire
wire [7:0] rom_data;

// Input clock gate
wire gclk;
assign clk_o = gclk;
clkgate vt_ckg (
	.in(clk),
	.gate(cke),
	.out(gclk)
);

always@(posedge gclk)
begin
	// coordinates counters
	if (rst) begin
		vr <= 0;
		hr <= 0;
	end else begin
		if (hr == h-2) begin
			hr <= 0;
			vr <= (vr == v-1) ? 0 : vr + 1;
		end else begin
			hr <= hr+2;
		end
	end

	// Actual pattern generation
		case (pattern)
			2'd0: begin
				rde <= 0;
				gde <= gmax;
				bde <= 0;
				rdo <= 0;
				gdo <= gmax;
				bdo <= 0;
			end
			2'd1: begin
				if (vr[0] ^ hr[0]) begin
					rde <= 0;
					gde <= 0;
					bde <= 0;
					rdo <= rmax;
					gdo <= gmax;
					bdo <= bmax;
				end else begin
					rde <= rmax;
					gde <= gmax;
					bde <= bmax;
					rdo <= 0;
					gdo <= 0;
					bdo <= 0;
				end
			end
			2'd2: begin
				if (rom_data[7-hr[2:0]]) begin
					rde <= rmax;
					gde <= gmax;
					bde <= bmax;
				end else begin
					rde <= 0;
					gde <= 0;
					bde <= 0;
				end
				if (rom_data[7-hrp1[2:0]]) begin
					rdo <= rmax;
					gdo <= gmax;
					bdo <= bmax;
				end else begin
					rdo <= 0;
					gdo <= 0;
					bdo <= 0;
				end
			end
			2'd3: begin
				rde <= hr[r-1:0] ^ vr[r-1:0];
				gde <= hr[g:1] ^ vr[g-1:0];
				bde <= hr[b-1:0] ^ vr[b:1];
				rdo <= hrp1[r-1:0] ^ vr[r-1:0];
				gdo <= hrp1[g:1] ^ vr[g-1:0];
				bdo <= hrp1[b-1:0] ^ vr[b:1];
			end
		endcase
end

// ROM with "mctom" bitmap
rom #(
	.m(32),
	.n(8),
	.data({8'h00,8'h00,8'h00,8'hfb,8'haa,8'h8b,8'h00,8'h00,8'h00,8'h10,8'h38,8'h93,8'h12,8'h93,8'h00,8'h00,8'h00,8'h00,8'h00,8'hbe,8'haa,8'ha2,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00}),
	.content_size(32)
) vt_rom (
	.clk(~gclk),
	.address({hr[4:3],vr[2:0]}),
	.data_o(rom_data)
);

endmodule
`endif
