// VGA Transmitter
// by Tomek Szczęsny 2023
//
// A simple transmitter, supporting external resistive DACs (VGA666 style).
// Generates HSync and VSync signals, including synchronization periods etc.
// Default timing and polarity params represent IBM 640x480@60Hz mode.
//
// Supports external FIFO pixel buffer (See fifo.v).
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
integer ht = hva + hfp + hsp + hbp;
integer vt = vva + vfp + vsp + vbp;

reg [$clog2(ht)-1:0] hs;	// horizontal state
reg [$clog2(vt)-1:0] vs;	// vertical state
reg fetch_gate;	
assign fetch = fetch_gate & clk;

initial HSync <= ~hpp;
initial VSync <= ~vpp;
initial R = 0;
initial G = 0;
initial B = 0;
initial fetch <= 0;
initial hs = 0;
initial vs = 0;
initial fetch_gate = 0;

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
	HSync <= (hs < hsp) ? hpp : ~hpp;
	VSync <= (vs < vsp) ? vpp : ~vpp;

	// Pass data to RGB outputs
	if ((hs>(hsp+hfp-1)) and (hs<(ht-hbp)) and (vs>(vsp+vfp-1)) and (vs<(vt-vbp))) begin
		B <= data[bd-1      :0    ];
		G <= data[bd+gd-1   :bd   ];
		R <= data[bd+gd+rd-1:bd+gd];
		fetch_gate <= 1;
	end else begin
		B <= 0;
		G <= 0;
		R <= 0;
		fetch_gate <= 0;
	end
end

endmodule

`endif
