//
// LUT + DFF + Carry combo
// by Tomek Szczesny 2024
//
// This instance can be used to build counters of exceptional efficiency,
// that are easy to daisy chain.
// For example highly optimized BCD counters or frequency dividers.
//
// LUT and Carry are internally connected together as defined in the hardware.
// The default LUT configuration represents the behavior of a binary counter bit.
//
// D Flip-Flop works on the posedge of clk and has clock enable input.
// Reset state can be defined as a parameter, and both synchronous and
// asynchronous options are available.
//
//              +---------------------------------------- cout      
//              |                                                               
//        +-----------+                                                         
//        |   Carry   |                                                         
//        +-----------+                                                        
//            | | |       +-------+             +-------+                               
// in0 ------------------>|       |      clk -->|       |                               
//            | | |       |       |      cke -->|       |                               
// in1 -------O---------->|       |             |       |                               
//              | |       |  LUT  |---- lo ---->|  DFF  |---------> out                 
// in2 -----------O------>|       |             |       |                              
//              |         |       |      rst -->|       |                               
// cin ---------O-------->|       |             |       |                              
//                        +-------+             +-------+                               
//                                                                
// Parameters:
// lut_init		- LUT configuration (default: counter)
// rs			- Reset State (0)
// sync			- Synchronous(1) or asynchronous(0) reset (1)
//
// Ports: 
//
// Notes:
// 1. In hardware, 'cin' can only be either 0, 1 or cout from another cell.
// However Yosys know its ways of sacrificing another cell to route any signal
// to 'cin'.
// 2. 'cout' can either be connected to cin of another cell, or
// to in3 of a cell without Carry.
//
//
`ifndef _primitives_v_
`define _primitives_v_

module lut_dff_carry(
	input wire in0,
	input wire in1,
	input wire in2,
	input wire cin,
	input wire clk,
	input wire cke,
	input wire rst,
	output wire out,
	output wire cout
);
// The default parameter configures LUT to act as a binary counter.
// in0 <= 0; in1 <= 0; in2 <= out; 
parameter lut_init = 16'b0000_1111_1111_0000;
parameter rs = 0;
parameter sync = 1;

wire lo;	// LUT Output

SB_CARRY carry (
	.CO(cout),
	.I0(in1),
	.I1(in2),
	.CI(cin)
);

SB_LUT4 lut (
	.O(lo),
	.I0(in0),
	.I1(in1),
	.I2(in2),
	.I3(cin)
);

case ({rs, sync})
	2'b00: SB_DFFER  dff (.Q(out), .C(clk), .E(cke), .D(lo), .R(rst));
	2'b01: SB_DFFESR dff (.Q(out), .C(clk), .E(cke), .D(lo), .R(rst));
	2'b10: SB_DFFES  dff (.Q(out), .C(clk), .E(cke), .D(lo), .S(rst));
	2'b11: SB_DFFESS dff (.Q(out), .C(clk), .E(cke), .D(lo), .S(rst));
endcase


defparam lut.LUT_INIT = lut_init;

endmodule

`endif
