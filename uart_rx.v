// Unbuffered UART Receiver
// by Tomek Szczęsny 2022
//
// Receives data in 8n1 format, at any clock rate.
// Performs user defined oversample (at least 4x).
// Theoretically should handle 2.5% clk frequency mismatch between tx and rx.
//
//             +------------------+
//      in --->|                  |---> out[8]
//             |      uart_rx     |
//     clk --->|                  |---> clk_out
//             +------------------+
//
// Parameters: 
// o		- Oversampling factor, o > 3
//
// Ports:
// clk		- a receiver clock input. Must be close to "o" * data rate.
// in		- UART input, typically a physical pin
// out[8] 	- 1-byte wide output register with received data
// clk_out	- Sends short positive pulse when out[8] is updated
//
// Tip: Higher oversampling factor may be helpful in obtain better clock
// frequency fit. Consider this example:
// System clock: 100 MHz
// UART baudrate: 4 M
// With oversampling = 5, the input clock is 20 MHz, which can be divided with
// no error.
//
`ifndef _uart_rx_v_
`define _uart_rx_v_

module uart_rx(
	input wire clk,
	input wire in,
	output reg [7:0] out = 0,
	output reg clk_out = 0

);

parameter o = 4;

reg [3:0] state = 0;		// Transmitter machine state
// 0		Idle
// 1		Start bit 
// 2 - 9	Data bits
// 10		Stop bit, out[8] update

reg [$clog2(o)-1:0] osc = 0;		// Oversample state counter
reg [$clog2(o)-1:0] osb = 0;		// Oversample ones counter
reg [7:0] oub = 0;			// Output buffer

wire arb = (osb + in) > (o/2);

always @(posedge clk)
begin
	// Waiting for start bit
	if (state == 0) begin
		clk_out <= 0;
		if (in == 0) begin
			state <= 1;
			osc <= 1;
			osb <= in;
		end
	end
	
	// Receiving start bit and checking its validity
	if (state == 1) begin
		osc <= osc + 1;
		osb <= osb + in;
		if (osc == o-1) begin
			if (~arb) begin
				state <= 2;
			end else begin
				state <= 0;
			end
			osb <= 0;
			osc <= 0;
		end

	end
	
	// Steadily advancing counters while receiving data bits
	// Also saving incoming data
	if (state > 1 && state < 10) begin
		osc <= osc + 1;
		osb <= osb + in;
		if (osc == o-1) begin
			state <= state + 1;
			//oub[state-2] <= (arb);
			oub[7] <= (arb);
			oub[6:0] <= oub[7:1];
			osb <= 0;
			osc <= 0;
		end
	end

	// While receiving stop bit, out is pushed and clk_out toggled
	// Stop part is cut short to 2 clock cycles in case receiver lags
	// behind the transmitter.
	if (state >= 10) begin
		osc <= osc + 1;
		if (osc == 0) out <= oub;
		if (osc == 1) clk_out <= 1;
		if (osc == 1) state <= 0;
	end

end

endmodule

`endif
