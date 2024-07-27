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
// data[8] 	- 1-byte wide input, latched after each start bit.
// out		- UART data output, typically wired to a physical pin.
// fetch	- Sends a positive pulse before data is latched.
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
// 0      Start bit, fetch pulse
// 1      First data bit, latching data[8] 
// 2 - 8  Sending the remaining bits of data
// 9 	  Stop bit

reg [6:0] int_buf;

always @(posedge clk)
begin
	if (state == 0 && data_rdy) begin
		out <= 0;
		fetch <= 1;
		state <= state + 1;
	end
	if (state == 1) begin
		int_buf[6:0] <= data[7:1];
		out <= data[0];
		fetch <= 0;
		state <= state + 1;
	end
	if (state > 1 && state < 9) begin
		//out <= int_buf[state - 1];
		out <= int_buf[0];
		int_buf[5:0] <= int_buf[6:1];
		fetch <= 0;
		state <= state + 1;
	end
	if (state == 9) begin
		out <= 1;
		state <= 0;
		fetch <= 0;
	end
end

endmodule

// UART Transmitter
// light edition
// by Tomek Szczęsny 2024
//
// Works like uart_tx except it doesn't generate fetch signal.
// The structure had been optimized for small size.
// 
// Also, since there is no "fetch" signal for the compatible receiver,
// data_rdy signal is posedge-sensitive, in order to avoid repeating the same
// frame from very slow transmitters.
//
//              +-------------+
//      clk --->|             |
//              |             |
//  data[8] ===>|  uart_tx_l  |---> out
//              |             |
// data_rdy --->|             |
//              +-------------+
//
//
// Parameters: none
//
// Ports:
// clk		- a transmitter clock input. Typically 9.6 kHz or 115.2 kHz.
// data_rdy	- Posedge indicates the data is ready to be sent.
// data[8] 	- 1-byte wide input, latched during each start bit.
// out		- UART data output, typically wired to a physical pin.
//

module uart_tx_l(
	input wire clk,
	input wire data_rdy,
	input wire[7:0] data,
	output reg out
);
initial out <= 1;
initial fetch <= 0;

reg [3:0] state;		// Transmitter machine state
// 0      Start bit, latch data
// 1      First data bit, latching data[8] 
// 2 - 8  Sending the remaining bits of data
// 9 	  Stop bit

reg dr[1:0] = 0;
always @ (posedge data_rdy) dr[0] <= ~dr[0];
wire drr;
assign drr = (dr[0] != dr[1]);

reg [7:0] int_buf;

always @(posedge clk)
begin
	if (state == 0 && drr) begin
		dr[1] <= ~dr[1];
		out <= 0;
		state <= state + 1;
		int_buf[7:0] <= data[7:0];
	end
	if (state > 0 && state < 10) begin
		out <= int_buf[0];
		int_buf[6:0] <= int_buf[7:1];
		int_buf[7] <= 1;
	end
	if (state > 0 && state < 9) begin
		state <= state + 1;
	end
	if (state > 8) begin
		out <= 1;
		state <= 0;
	end
end

endmodule
`endif
