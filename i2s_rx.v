// I2S Receiver
// by Tomek Szczęsny 2022
//
// Warning: This design has not been tested yet.
//
// Typically connected to external pins, it receives I2S signals and 
// has buffered output L and R channel PCM frames.
//
//             +------------------+
//     sck --->|                  |
//             |                  |===> l[b]
//      ws --->|      i2s_rx      |
//             |                  |===> r[b]
//      sd --->|                  |
//             +------------------+
//
// Parameters:
// b	- Output PCM bit depth (16)
//
// Ports:
// sck	- I2S Continuous Serial Clock
// ws	- I2S Word Select
// sd	- I2S Serial Data
// l[b]	- Left channel PCM output
// r[b] - Right channel PCM output

module i2s_rx(
	input wire sck,
	input wire ws,
	input wire sd,
	output reg [b-1:0] l = 0,
	output reg [b-1:0] r = 0
);
parameter b = 16;

reg [b-1:0] rxbuf = 0;		// Receiver buffer
reg ch = 0;			// Last WS state
reg [4:0] cnt = 0;		// Bit counter for current word
reg dump = 0;			// Schedule output dump on next sck cycle


always @ (posedge sck)
begin
	ch <= ws;

	if (cnt < b) begin
		rxbuf[b-1-cnt] <= sd;
	end

	if (ch != ws) begin
		dump <= 1;
		cnt <= 0;
	end else begin
		cnt <= cnt + 1;
		dump <= 0;
		if (dump == 1) begin
			if (ws == 0) begin
				l <= rxbuf;
			end else begin
				r <= rxbuf;
			end
		end
	end

end

// Note: rxbuf is never cleared, just overwritten. It may render some
// negligible side effects if input stream bit depth gets reduced
// unexepectedly.

endmodule
