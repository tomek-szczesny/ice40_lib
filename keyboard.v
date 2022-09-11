`ifndef _keyboard_v_
`define _keyboard_v_

// Key matrix receiver
// by Tomek Szczęsny 2022
//
// WARNING: This module is only partially tested to date. No testbench will be
// provided as it largely deals with an actual hardware.
//
// This module scans a passive matrix of keys (such as laptop keyboards)
// that is connected directly to FPGA pins.
// Reverse engineering tool is provided as a separate module below, that helps
// figure out which keyboard wires are rows or columns.
//
// By convention adopted in this work, "rows" are outputs, and "cols" are inputs
// from the FPGA perspective.
// For the most popular, completely passive matrices it doesn't matter
// and can be treated interchangeably. More sophisticated keyboards may
// include diodes that prevent ghosting, in which case it is important to
// distinguish between rows and columns. Diode cathodes shall point at rows.
// 
// This module scans key matrix at the rate of user-provided clock, one row
// per clock cycle. It always scans through all combinations of rows and columns
// even if there are no keys associated with them (those will always read "0").
// Thus the recommended clock rate is about 8-16 kHz for a laptop keyboard
// with 8-16 rows.
//
// This module exposes the current row number as a minimal unsigned integer,
// and key statuses for each column in the active row. 
// 
//                 +-------------------+
//         clk --->|                   |
// row_pins[r] ===>|   key_matrix_rx   |===> row[clog2(r)]
// col_pins[c] ===>|                   |===> cols[c]
//                 +-------------------+
//
// Parameters:
// r		- Number of row pins (16)
// c		- Number of column pins (8)
//
// Ports:
// clk		- an input clock. Typically 1kHz per each row/col combination
// row_pins[r]	- Physical FPGA pins connected to the key matrix rows
// col_pins[c]	- Physical FPGA pins connected to the key matrix columns
// row[clog2(c)]- Current row number
// cols[c]	- Key statuses on respective columns, for a current row
//
module key_matrix_rx (
	input wire clk,				// master clock 
	output wire [r-1:0] row_pins,		// Physical pins
	input wire [c-1:0] col_pins,		// Same here
	output reg [$clog2(r)-1:0] row = 0,
	output wire [c-1:0] cols
);

parameter r = 16; // Number of rows
parameter c = 8; // Number of cols

// Initializing outputs
// Outputs are either "0" or "z"
// which corresponds to row_out "1" and "0" respectively
// Outputs are meant to be iterated through using 1-of-n counter
SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    .PULLUP(1'b 1)
) row_sb_io [r-1:0] (
    .PACKAGE_PIN(row_pins),
    .OUTPUT_ENABLE(row_out),
    .D_OUT_0(1'b 0)
);

// Initializing inputs
SB_IO #(
    .PIN_TYPE(6'b 0000_01),
    .PULLUP(1'b 1)
) col_sb_io [c-1:0] (
    .PACKAGE_PIN(col_pins),
    .D_IN_0(col_in)
);

wire [c-1:0] col_in;
assign cols = ~col_in;

wire [r-1:0] row_out;
assign row_out = (1 << row);

always @ (posedge clk)
begin
	// Advance counter
	if (row < r - 1) begin
		row <= row + 1;
	end else begin
		row <= 0;
	end
end

endmodule

// -----------------------------------------------------------------------------
// Reverse engineering tool for keyboard matrices
// by Tomek Szczęsny 2022
//
// WARNING: This module is only partially tested to date. No testbench will be
// provided as it largely deals with an actual hardware.
//
// This module is intended for development use only. Its primary use is to
// completely reverse engineer an unknown key matrix.
//
// Unlike "key_matrix_rx" module, this one uses all pins as potential inputs
// and outputs. An algorithm sweeps through all available pins and senses if
// it is shorted with any other pin - which is the case when a button is
// pressed.
// This enables the user to map all matrix keys to pairs of pins.
//
// Knowing this, and assuming that each key must be connected to exactly one
// row and one column, it is easy to work out which pins belong to each group.
//
// In case of passive key matrices (you may assume that if unsure), a short
// will be detected twice during a scan - from pin A to B, and from pin B to A.
// If only one short is detected, for example A to B, that means the matrix is
// not passive and may contain anti-ghosting diodes, lucky you. In that case,
// it's important to acknowledge that "A" is a row. Otherwise, rows and
// columns are interchangeable concepts.
//
// This module scans through each pin combination. If a short is detected, it
// clocks out two bytes of data:
// - A number of tx pin (the one forced to low state)
// - A number of rx pin (the one sensed as low even though it's not driven)
//
// These outputs may be directly hooked up to uart_tx module inputs and then
// inspected on uart-aware scope or a Linux machine.
//
// Tip: Since the typical output values are in control characters range of
// ASCII standard, make sure you set your UART receiver to RAW mode.
//
// 
//             +------------------+                            + - - - - - - +
//     clk --->|                  |                                           
// pins[p] ===>|  key_matrix_rev  |===> out[8] - - data[8] ===>|   uart_tx   |
//             |                  |---> clk_out - -  write --->               
//             +------------------+                            + - - - - - - +
//
// Parameters:
// p		- Number of pins (24)
//
// Ports:
// clk		- an input clock. Typically 10 - 50kHz
// pins[p]	- Physical FPGA pins connected to the key matrix
// out[8]	- Output data
// clk_out	- Output clock
//
// NOTE: out[8] may expose meaningless data that is not to be interpreted
// without clk_out posedge.
//

module key_matrix_rev (
	input wire clk,
	inout wire [p-1:0] pins,
	output reg [7:0] out,
	output reg clk_out
);

parameter p = 24;

wire [p-1:0] pin_out;
wire [p-1:0] pin_in;

//Initializing IO
// Outputs are either "0" or "z"
// which corresponds to pin_out "1" and "0" respectively
// Outputs are meant to be iterated through using 1-of-n counter
SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    .PULLUP(1'b 1)
) pins_sb_io [p-1:0] (
    .PACKAGE_PIN(pins),
    .OUTPUT_ENABLE(pin_out),
    .D_OUT_0(1'b 0),
    .D_IN_0(pin_in)
);

reg [7:0] out_cntr = 0;	// Output counter
assign pin_out = (1 << out_cntr);

reg [7:0] in_cntr = 0; // Input counter
reg [2:0] u_cyc = 0;
// Micro cycles:
// 0 - advance counters, prepare first byte of data
// 1 - drive clk_out high if short detected
// 2 - clk_out <= 0; Prepare second byte
// 3 - "Send" second byte

always @ (posedge clk)
begin

	if (u_cyc == 0) begin
		// Advance counters
		if (in_cntr < p - 1) begin
			in_cntr <= in_cntr + 1;
		end else begin
			in_cntr <= 0;
			if (out_cntr < p - 1) begin
				out_cntr <= out_cntr + 1;
				out      <= out_cntr + 1;
			end else begin
				out_cntr <= 0;
				out      <= 0;
			end
		end

		u_cyc <= 1;
		clk_out <= 0;
	end

	if (u_cyc == 1) begin
		if (~pin_in[in_cntr] && (in_cntr != out_cntr)) begin
			clk_out <= 1;
			u_cyc <= 2;
		end else begin
			u_cyc <= 0;
		end
	end

	if (u_cyc == 2) begin
		u_cyc <= 3;
		clk_out <= 0;
		out <= in_cntr;
	end

	if (u_cyc == 3) begin
		u_cyc <= 0;
		clk_out <= 1;
	end

end

endmodule

`endif
