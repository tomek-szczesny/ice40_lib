// I2S Receiver
// by Tomek Szczęsny 2022
//
// Typically connected to external pins, it receives I2S signals and 
// has buffered output L and R channel PCM frames.
//
// As per I2S standard, this receiver is compatible with any bit depth of the
// sender, by either ignoring excessive LSBs or concatenating missing LSB
// zeroes.
//
//             +------------------+
//     sck --->|                  |===> l[b]
//             |                  |
//      ws --->|      i2s_rx      |===> r[b]
//             |                  |
//      sd --->|                  |---> ock
//             +------------------+
//
// Parameters:
// b	- Output PCM bit depth (b < 64) (16)
//
// Ports:
// sck	- I2S Continuous Serial Clock
// ws	- I2S Word Select
// sd	- I2S Serial Data
// l[b]	- Left channel PCM output
// r[b] - Right channel PCM output
// ock	- Output clk. Posedge and negedge on r[b] and l[b] update, respectively.
//
`ifndef _i2s_rx_v_
`define _i2s_rx_v_

module i2s_rx(
	input wire sck,
	input wire ws,
	input wire sd,
	output reg [b-1:0] l = 0,
	output reg [b-1:0] r = 0,
	output reg ock = 0
);
parameter b = 16;

reg [b-1:0] rxbuf = 0;		// Receiver buffer
reg ch = 0;			// Last WS state
reg [5:0] cnt = 0;		// Bit counter for current word
reg dump = 0;			// Schedule output dump on next sck cycle


always @ (posedge sck)
begin
	ch <= ws;

	if (cnt < b) begin
		rxbuf[b-1-cnt] <= sd;
	end

	if (cnt == 0) begin
		rxbuf[b-2:0] <= 0;
	end

	if (ch != ws) begin
		dump <= 1;
		cnt <= 0;
	end else begin
		cnt <= cnt + 1;
		dump <= 0;
		if (dump == 1) begin
			if (ws == 0) begin
				r <= rxbuf;
				ock <= 1;
			end else begin
				l <= rxbuf;
				ock <= 0;
			end
		end
	end

end

endmodule

`endif
