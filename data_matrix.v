`ifndef _uart_matrix_v_
`define _uart_matrix_v_

// Data matrix
// by Tomek Szczęsny 2024
//
// This module connects multiple parallel interfaces together.
//
// Inputs are designed to be connected to FIFO output ports.
// Outputs are designed to work with FIFO input ports.
//
// Data from input FIFOs is redistributed to output FIFOs according to
// the configuration stored in the external LUT.
// Any input can be connected to any output, including multiple outputs.
//
// The module checks for new data on the inputs in round-robin fashion.
// New data frame is being forwarded to all output buffers indicated in the LUT.
// This happens in a single clk cycle.
// 
// Each row in the LUT corresponds to RX port of the matrix.
// Each bit in the LUT row indicates TX ports for the data to be forwarded to.
// Any LUT configuration is valid.
//
//                                                                              
//                  +---------------+                          + - - - - - - -
//                  |               |                                     
//          clk --->|               |                  clk --->| fifo_cke_n[n]
//                  |               |                            (tx buffers)         
//      rx[m*o] ===>|  data_matrix  |===> tx[o] == data[o] ===>| shared tx[o] 
//    rx_pop[m] <---|               |                            individual cke
//    rx_rdy[m] --->|               |===> tx_cke[n] -- cke --->|
//                  |               |                                     
//     lut[n*m] ===>|               |                          + - - - - - - -     
//                  +---------------+
//                                                                              
// Parameters:
// m		- number of input (rx) ports
// n		- number of output (tx) ports
// o		- Parallel data width (both input and output)
//
// Ports:
// clk		- an input clock
// rx[m*o]	- inputs for parallel data
// rx_pop[m]	- Outputs for removing a value from input FIFO
// rx_rdy[m]	- Input indicating that data is ready to be fetched
// lut[n*m]	- External LUT input. Can be manipulated by external logic
// tx[o]	- Parallel data output, connect to all output FIFOs
// tx_cke[n]	- FIFO clock enable signal outputs, one for each FIFO
//

module data_matrix (
	input wire clk,				// master clock 
	input wire [m*o-1:0] rx,
	output reg [m-1:0] rx_pop = 0,
	input wire [m-1:0] rx_rdy,
	input wire [n*m-1:0] lut,
	output reg [o-1:0] tx,
	output reg [n-1:0] tx_cke
);

parameter m = 8;
parameter n = 8;
parameter o = 8;

reg [$clog2(m-1):0] inc = 0;	// Input counter for round-robin operation

//////////////

always @ (posedge clk)
begin
	// advance counter
	if (inc == m-1) inc <= 0;
	else inc <= inc + 1;

	// The action
	if (rx_rdy[inc]) begin
		tx_cke <= lut[inc];
		rx_pop[inc] <= 1;
	end else begin
		rx_pop <= 0;
		tx_cke <= 0;
	end
	tx <= rx[(inc+1)*o-1:inc*o];
end

endmodule

`endif
