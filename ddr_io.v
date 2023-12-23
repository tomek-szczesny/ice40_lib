// Dual Data Rate Input/Output library
// by Tomek Szczęsny 2023
//
// These modules initialize ice40 GPIOs to work in DDR mode.
// Which means that input or output pin is triggered by both rising and
// falling clock edge, achieving double data transfer speed.
//
// All have configurable FIFOs, so "SDR logic" can keep up with
// them.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// Single-ended DDR outputs
// Data is fed through two vectors, "p" and "n". Both vectors accept data on
// clk posedge. The contents "p" vector are clocked out first.
//
//                 +-------------------+
//         clk --->|                   |
//   data_p[n] ===>|      ddr_out      |===> data_o[n] (physical pins)
//   data_n[n] ===>|                   |
//                 +-------------------+
//
// Parameters:
// n		- Number of output pins (8)
//
// Ports:
// clk		- clock input
// data_p[n]	- Data clocked in on clk posedge, out on posedge
// data_n[n]	- Data clocked in on clk posedge, out on negedge
// data_o[n]	- Data output, physical pins only
//
`ifndef _ddr_io_v_
`define _ddr_io_v_

module ddr_out (
	input wire clk,	
	input wire [n-1:0] data_p,
	input wire [n-1:0] data_n,
	output reg [n-1:0] data_o
);
parameter n = 8;

// data_n contents must be held in a register, to be accessed on negedge later
reg [n-1:0] data_n_r;
always @ (posedge clk) data_n_r <= data_n;


// Physical outputs
SB_IO #(
    .PIN_TYPE(6'b0100_00),
    .PULLUP(1'b0)
) ddr_out_sb_io [n-1:0] (
    .D_OUT_0(data_p),
    .D_OUT_1(data_n_r),
    .PACKAGE_PIN(data_o),
    .OUTPUT_CLK(clk),
    .INPUT_CLK(clk)
);

endmodule

`endif
