// Buffered UART Transmitter
// by Tomek Szczęsny 2022
//
// Sends data in 8n1 format, at any clock rate.
//
// Uses iCE40 4kb RAM block as 512B circular buffer.
//
// TODO: Buffer overflow corrupts data with stuff of unclear origin.
// Just don't overflow the buffer and you'll be fine. It's 512B after all.
// 
//
//             +------------------+
//     clk --->|                  |---> out
//             |                  |        
//             |      uart_tx     |
//   write --->|                  |---> busy
// data[8] ===>|                  |
//             +------------------+
//
// Parameters: none
//
// Ports:
// clk		- a transmitter clock input. Typically 9.6 or 115.2 kHz.
// write	- input buffer control, stores data at posedge.
// data[8] 	- 1-byte wide input fetched at each "write" posedge.
// out		- UART data output, typically wired to a physical pin.
// busy		- Buffer full indicator.
//

module uart_tx(
	input wire clk,
	input wire write,
	input wire[7:0] data,
	output reg out,
	output wire busy
);
initial out <= 1;

reg [3:0] state;		// Transmitter machine state
// 0      Start bit (and fetch buffer data)
// 1 - 8  Sending 8 bits of data
// 9 	  Stop bit

reg [8:0] buf_top = 0;
reg [8:0] buf_bot = 0;
reg [7:0] buf_out;
reg buf_out_trig = 0;

reg [7:0] tx_buf [0:511];

assign busy = ((buf_bot - buf_top) == 1);
wire data_pending;
assign data_pending = (buf_top != buf_bot);

always @(posedge clk)
begin
	if(data_pending) begin
		if (state == 0) begin
			out <= 0;
			buf_out_trig <= 1;
			state <= state + 1;
		end
		if (state > 0 && state < 9) begin
			out <= buf_out[state - 1];
			state <= state + 1;
		end
		if (state >= 9) begin
			out <= 1;
			buf_bot <= buf_bot + 1;
			buf_out_trig <= 0;
			state <= 0;
		end
	end
end

always @(posedge buf_out_trig)
begin
	buf_out <= tx_buf[buf_bot];
end

always @(posedge write)
begin
	if (busy == 0)
	begin
		tx_buf[buf_top] <= data;
		buf_top <= buf_top + 1;
	end
end

endmodule
