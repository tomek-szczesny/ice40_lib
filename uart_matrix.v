`ifndef _uart_matrix_v_
`define _uart_matrix_v_

// UART matrix
// by Tomek Szczęsny 2024
//
// This module connects multiple UART interfaces together.
//
// Inputs are UART streams clocked at the module's clk rate.
// The real life UART streams must be reclocked to this rate.
// This is to avoid routing m*8 signals to this module.
//
// The outputs are interfaces working with TX FIFOs of physical UART ports.
//
// The module checks for new data on UART inputs in round-robin fashion.
// New data frame is being forwarded to all TX buffers indicated in the LUT.
// This happens in a single clk cycle.
// Since there are single-frame RX buffers, the matrix theoretically may be
// overwhelmed if there's more than 10 input ports. 
// 
// Each row in the LUT corresponds to RX port of the matrix.
// Each bit in the LUT row indicates TX ports for the data to be forwarded to.
// Any number of TX ports can be selected at any given time.
//
//               +--------------------------------+                             
//               |                                |                             
//               |  +---------------+             |            + - - - - - - -
//               |  |               |             |                       
//          clk -+->|               |             +--- clk --->|  fifo_cke[n]
//                  |               |                            (tx buffers)         
//        rx[m] ===>|  uart_matrix  |===> tx[8] == data[8] ===>| shared tx[8] 
//                  |               |                            individual cke
//  lut_data[n] ===>|               |===> tx_cke[n] -- cke --->|
//  lut_addr[m] ===>|               |                                     
//      lut_cke --->|               |                          + - - - - - - -     
//                  +---------------+
//                                                                              
// Parameters:
// m		- number of input (rx) ports
// n		- number of output (tx) ports
//
// Ports:
// clk		- an input clock
// rx[m]	- inputs for UART data streams, clocked at clk
// lut_addr[m]	- LUT interface; row selection input
// lut_data[n]	- LUT interface; row data input
// lut_cke	- LUT interface; clock enable input
// tx[8]	- Parallel data frame output, connect to all FIFOs
// tx_cke[n]	- FIFO clock enable signal outputs, one for each FIFO
//

module uart_matrix (
	input wire clk,				// master clock 
	input wire [m-1:0] rx,
	input wire [n-1:0] lut_data,
	input wire [m-1:0] lut_addr,
	input wire lut_cke,
	output reg [7:0] tx,
	output reg [n-1:0] tx_cke
);

parameter m = 8;
parameter n = 8;

reg [$clog2(m-1):0] inc = 0;	// Input counter for round-robin operation
reg [n-1:0] lut [0:m-1] ;	// Matrix configuration LUT

// Input data stream receivers, with a twist
// Each must signal that new data is present.
// This is accomplished by the uart_rx wrapper
// defined in a separate module below.
wire [7:0]   rx_out [0:m-1];
reg  [m-1:0] rx_reset;
wire [m-1:0] rx_newdata;

uart_matrix_rx rx_core [m-1:0] (
	.clk(clk),
	.in(rx),
	.out(rx_out),
	.reset(rx_reset),
	.newdata(rx_newdata)
);

//////////////

always @ (posedge clk)
begin
	// LUT
	if (lut_cke) lut[lut_addr] <= lut_data;

	// advance counter
	if (inc == m-1) inc <= 0;
	else inc <= inc + 1;

	// The action
	if (rx_newdata[inc]) begin
		tx <= rx_out[inc];
		tx_cke <= lut[inc];
		rx_reset <= 1'b1 << inc;
	end else begin
		tx_cke <= 0;
		rx_reset <= 0;
	end
end

endmodule

//
// uart_rx_no wrapper with new data signaling
//
`include "uart_rx.v"
module uart_matrix_rx (
	input wire clk,
	input wire in,
	output wire [7:0] out,
	input wire reset,
	output reg newdata
);
	wire clk_out;
	uart_rx_no rx (
		.clk(clk),
		.in(in),
		.out(out),
		.clk_out(clk_out)
	);
	always @ (posedge clk_out, posedge reset)
	begin
		if (reset) newdata <= 0;
		else newdata <= 1;
	end
endmodule

`endif
