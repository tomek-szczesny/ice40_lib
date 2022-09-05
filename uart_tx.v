// Buffered UART Transmitter
// by Tomek Szczęsny 2022
//
// Uses iCE40 4kb RAM block as 512B circular buffer.
// Sends data in 8n1 format, at any input clock rate.
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
// "clk" is a clock input for transmitter operation. Typically 9600 Hz or 115200 Hz.
// "data[8]" is stored in output buffer on each "write" posedge.
// "out" is UART data output, typically wired to a physical pin.
// "busy" is high if buffer is full and new data is being discarded.
//

module uart_tx(
	input wire clk,		// Clock input (clocks output)
	input wire write,	// Posedge writes data to a buffer
	input wire[7:0] data,	// 8-bit data input
	output reg out,	        // Output that should go to physical output pin
	output wire busy	// The buffer is full, new data will be discarded
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
