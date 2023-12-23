// VGA Transmitter
// by Tomek Szczęsny 2023
//
// A simple transmitter, supporting external resistive DACs (VGA666 style).
// Generates HSync and VSync signals, including synchronization periods etc.
// Default timing and polarity params represent IBM 640x480@60Hz mode.
//
// Supports external FIFO pixel buffer (See fifo.v).
//
// vga_tx_ddr variant available below.
//
//  - - - - - +                                        +-----------+
//                                             clk --->|           |===> R[rd]
//     fifo   |                                        |           |===> G[gd]
//  n=rd+gd+bd = => data_o = = = => data[rd+gd+bd] ===>|   vga_tx  |===> B[bd]
//            |                                        |           |---> HSync
//                                                     |           |---> VSync
//  - - - - - +                                        +-----------+
//          ^                                                |      
//    clk_o + - - - - - - - - - - - - - - - - - - - - - - - - ---------> fetch
//
//
//
//
// Parameters:
// rd		- bit depth of R channel (8)
// gd		- bit depth of G channel (8)
// bd		- bit depth of B channel (8)
// hva		- horizontal visible area (image size) (640)
// hfp		- horizontal front porch (in pixels) (16) // before sync pulse
// hsp		- horizontal sync pulse (in pixels) (96)
// hbp		- horizontal back porch (in pixels) (48)  // after sync pulse
// vva		- vertical visible area (image size) (480)
// vfp		- vertical front porch (in pixels) (10)
// vsp		- vertical sync pulse (in pixels) (2)
// vbp		- vertical back porch (in pixels) (33)
// hpp		- horizontal sync pulse polarity (0)
// vpp		- vertical sync pulse polarity (0)
//
//
// Ports:
// clk		- transmitter clock input. 25.175MHz for default settings.
// data[rd+gd+bd] - RGB data input, must always be valid. "R" bits are MSBs.
// R[rd]	- R channel output
// G[gd]	- G channel output
// B[bd]	- B channel output
// HSync	- Horizontal sync output
// VSync	- Vertical sync output
// fetch	- Sends a positive pulse after data has been read
//
`ifndef _vga_tx_v_
`define _vga_tx_v_
`include "clkgate.v"

module vga_tx(
	input wire clk,
	input wire[rd+gd+bd-1:0] data,
	output reg[rd-1:0] R,
	output reg[gd-1:0] G,
	output reg[bd-1:0] B,
	output reg HSync,
	output reg VSync,
	output wire fetch
);
parameter rd = 8;
parameter gd = 8;
parameter bd = 8;
parameter hva = 640;
parameter hfp = 16;
parameter hsp = 96;
parameter hbp = 48;
parameter vva = 480;
parameter vfp = 10;
parameter vsp = 2;
parameter vbp = 33;
parameter hpp = 0;
parameter vpp = 0;
localparam ht = hva + hfp + hsp + hbp;
localparam vt = vva + vfp + vsp + vbp;

reg [$clog2(ht)-1:0] hs;	// horizontal state
reg [$clog2(vt)-1:0] vs;	// vertical state
wire fetch_gate;	
clkgate vga_tx_ckg (
	.in(clk),
	.gate(fetch_gate),
	.out(fetch)
);

initial HSync <= ~hpp;
initial VSync <= ~vpp;
initial R = 0;
initial G = 0;
initial B = 0;
initial hs = 0;
initial vs = 0;

// Fetch logic
assign fetch_gate = (hs == ht-1 || hs < hva-1) && (vs == vt-1 || vs < vva-1);

always @(posedge clk)
begin
	// Advance state counters
	if (hs < ht-1) begin
		hs <= hs+1;
	end else begin
		hs <= 0;
		if (vs < vt-1) begin
			vs <= vs+1;
		end else begin
			vs <= 0;
		end
	end

	// Generate sync pulses
	HSync <= (hs>=hva+hfp && hs < ht-hbp) ? hpp : ~hpp;
	VSync <= (vs>=vva+vfp && vs < vt-vbp) ? vpp : ~vpp;

	// Pass data to RGB outputs
	if (hs<hva && vs<vva) begin
		B <= data[bd-1      :0    ];
		G <= data[bd+gd-1   :bd   ];
		R <= data[bd+gd+rd-1:bd+gd];
	end else begin
		B <= 0;
		G <= 0;
		R <= 0;
	end
end

endmodule

// 
// vga_tx_ddr
//
// Shares the same io, parameters and functionality as vga_tx, except its 
// "data" input and all outputs have doubled widths.
// Least significant bits are meant to be clocked out first.
//
// It is designed to work with "ddr_out" module, see ddr_io.v.
//
// Note: Only even horizontal resolutions are supported.

module vga_tx_ddr(
	input wire clk,
	input wire[2*(rd+gd+bd)-1:0] data,
	output reg[2*rd-1:0] R,
	output reg[2*gd-1:0] G,
	output reg[2*bd-1:0] B,
	output reg[1:0] HSync,
	output reg[1:0] VSync,
	output wire fetch
);
parameter rd = 8;
parameter gd = 8;
parameter bd = 8;
parameter hva = 640;
parameter hfp = 16;
parameter hsp = 96;
parameter hbp = 48;
parameter vva = 480;
parameter vfp = 10;
parameter vsp = 2;
parameter vbp = 33;
parameter hpp = 0;
parameter vpp = 0;
localparam ht = hva + hfp + hsp + hbp;
localparam vt = vva + vfp + vsp + vbp;
localparam n  = rd + gd + bd;

reg [$clog2(ht)-1:0] hs;	// horizontal state
wire [$clog2(ht)-1:0] hsp1;
assign hsp1 = hs | 1'b1;	// hs plus one (hs is always even)

reg [$clog2(vt)-1:0] vs;	// vertical state
wire fetch_gate;	
clkgate vga_tx_ckg (
	.in(clk),
	.gate(fetch_gate),
	.out(fetch)
);

initial HSync <= {~hpp,~hpp};
initial VSync <= {~vpp,~vpp};
initial R = 0;
initial G = 0;
initial B = 0;
initial hs = 0;
initial vs = 0;

// Fetch logic
assign fetch_gate = (hs == ht-2 || hs < hva-2) && (vs == vt-1 || vs < vva-1);

always @(posedge clk)
begin
	// Advance state counters
	if (hs < ht-2) begin
		hs <= hs+2;
	end else begin
		hs <= 0;
		if (vs < vt-1) begin
			vs <= vs+1;
		end else begin
			vs <= 0;
		end
	end

	// Generate sync pulses
	HSync[0] <= (hs>=hva+hfp && hs < ht-hbp) ? hpp : ~hpp;
	HSync[1] <= (hsp1>=hva+hfp && hsp1 < ht-hbp) ? hpp : ~hpp;
	VSync[0] <= (vs>=vva+vfp && vs < vt-vbp) ? vpp : ~vpp;
	VSync[1] <= (vs>=vva+vfp && vs < vt-vbp) ? vpp : ~vpp;

	// Pass data to RGB outputs
	if (hs<hva && vs<vva) begin
		B[bd-1  : 0] <= data[  bd      -1:0      ];
		G[gd-1  : 0] <= data[  bd+gd   -1:  bd   ];
		R[rd-1  : 0] <= data[  bd+gd+rd-1:  bd+gd];
		B[2*bd-1:bd] <= data[n+bd      -1:n      ];
		G[2*gd-1:gd] <= data[n+bd+gd   -1:n+bd   ];
		R[2*rd-1:rd] <= data[n+bd+gd+rd-1:n+bd+gd];
	end else begin
		B <= 0;
		G <= 0;
		R <= 0;
	end
end

endmodule

`endif
