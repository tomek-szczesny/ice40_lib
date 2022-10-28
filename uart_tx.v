// UART Transmitter
// by Tomek Szczęsny 2022
//
// Sends data in 8n1 format, at any clock rate.
//
// Buffers one byte of input data while transmitting.
//
// Supports external FIFO buffer (See fifo.v).
// 
//
//  - - - - - +                                        +-----------+
//                                             clk --->|           |
//     fifo   |                                        |           |
//    n = 8    = => data_o  = = = = = = => data[8] ===>|  uart_tx  |---> out
//            |                                        |           |
//             = => status[0] - - - - - > data_rdy --->|           |---> fetch
//  - - - - - +                                        +-----------+ |
//          ^                                                        |
//    clk_o + - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
//
//
//
// Parameters: none
//
// Ports:
// clk		- a transmitter clock input. Typically 9.6 kHz or 115.2 kHz.
// data_rdy	- High state indicates the data is ready to be sent.
// data[8] 	- 1-byte wide input, fetched at each "write" posedge.
// out		- UART data output, typically wired to a physical pin.
// fetch	- Sends a positive pulse after data has been fetched.
//
`ifndef _uart_tx_v_
`define _uart_tx_v_

module uart_tx(
	input wire clk,
	input wire data_rdy,
	input wire[7:0] data,
	output reg out,
	output reg fetch
);
initial out <= 1;
initial fetch <= 0;

reg [3:0] state;		// Transmitter machine state
// 0      Start bit (and fetch buffer data)
// 1 - 8  Sending 8 bits of data
// 9 	  Stop bit

reg [7:0] int_buf;

always @(posedge clk)
begin
	if (state == 0 && data_rdy) begin
		int_buf <= data;
		out <= 0;
		fetch <= 1;
		state <= state + 1;
	end
	if (state > 0 && state < 9) begin
		out <= int_buf[state - 1];
		fetch <= 0;
		state <= state + 1;
	end
	if (state >= 9) begin
		out <= 1;
		state <= 0;
	end
end

endmodule

`endif
