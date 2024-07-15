// Unbuffered UART Receiver
// by Tomek Szczęsny 2022
//
// Receives data in 8n1 format, at any clock rate.
// Performs user defined oversample (at least 4x).
// Theoretically should handle 2.5% clk frequency mismatch between tx and rx.
//
//             +------------------+
//      in --->|                  |===> out[8]
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

reg [3:0] state = 0;		// Receiver machine state
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
			state <= state + 1;
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
				state <= state + 1;
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

// Unbuffered UART Receiver with variable oversampling factor
// by Tomek Szczęsny 2024
//
// Oversampling factor is latched in on every start bit.
//
//             +------------------+
//      in --->|                  |===> out[8]
//   o[ow] ===>|    uart_rx_vo    |
//     clk --->|                  |---> clk_out
//             +------------------+
//
// Parameters: 
// ow		- 'o' input width, ow >= 3 (3)
//
// Ports:
// o		- Oversampling factor, o > 3
// clk		- a receiver clock input. Must be close to "o" * data rate.
// in		- UART input, typically a physical pin
// out[8] 	- 1-byte wide output register with received data
// clk_out	- Sends short positive pulse when out[8] is updated
//
//

module uart_rx_vo(
	input wire clk,
	input wire in,
	input wire [ow-1:0] o,
	output reg [7:0] out = 0,
	output reg clk_out = 0

);

parameter ow = 3;

reg [3:0] state = 0;		// Receiver machine state
// 0		Idle
// 1		Start bit 
// 2 - 9	Data bits
// 10		Stop bit, out[8] update

reg [ow-1:0] ob = 3;			// Oversample factor buffer
reg [ow-1:0] osc = 0;			// Oversample state counter
reg [ow-1:0] osb = 0;			// Oversample ones counter
reg [7:0] oub = 0;			// Output buffer

wire arb = (osb + in) > (ob >> 1);

always @(posedge clk)
begin
	// Waiting for start bit
	if (state == 0) begin
		clk_out <= 0;
		if (in == 0) begin
			state <= state + 1;
			ob <= o;
			osc <= 1;
			osb <= in;
		end
	end
	
	// Receiving start bit and checking its validity
	if (state == 1) begin
		osc <= osc + 1;
		osb <= osb + in;
		if (osc == ob-1) begin
			if (~arb) begin
				state <= state + 1;
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
		if (osc == ob-1) begin
			state <= state + 1;
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

// Unbuffered UART Receiver with variable oversampling factor
// and resettable "data ready" latch
// by Tomek Szczęsny 2024
//
// Oversampling factor is latched in on every start bit.
// Positive dr_rst pulse asynchronously resets dr.
//
//             +---------------+               faster_clk --->+ - - - - - - - -                  
//      in --->|               |===> out[8] = = = data[8] ===>                                  
//   o[ow] ===>| uart_rx_vo_dr |<--- dr_rst - - - - fetch <---|     uart_tx                 
//     clk --->|               |---> dr - - - -  data_rdy --->     (reclock)                 
//             +---------------+                              + - - - - - - - -
//
// Parameters: 
// ow		- 'o' input width, ow >= 3 (3)
//
// Ports:
// o		- Oversampling factor, o > 3
// clk		- a receiver clock input. Must be close to "o" * data rate.
// in		- UART input, typically a physical pin
// out[8] 	- 1-byte wide output register with received data
// dr		- Positive logic Data Ready signal
// dr_rst	- Data Ready Reset
//
//

module uart_rx_vo_dr(
	input wire clk,
	input wire in,
	input wire [ow-1:0] o,
	output reg [7:0] out = 0,
	input wire dr_rst,
	output reg dr = 0
);

parameter ow = 3;

reg [3:0] state = 0;		// Receiver machine state
// 0		Idle
// 1		Start bit 
// 2 - 9	Data bits
// 10		Stop bit, out[8] update

reg [ow-1:0] ob = 3;			// Oversample factor buffer
reg [ow-1:0] osc = 0;			// Oversample state counter
reg [ow-1:0] osb = 0;			// Oversample ones counter
reg [7:0] oub = 0;			// Output buffer

wire arb = (osb + in) > (ob >> 1);

always @(posedge clk)
begin
	// Waiting for start bit
	if (state == 0) begin
		if (in == 0) begin
			state <= state + 1;
			ob <= o;
			osc <= 1;
			osb <= in;
		end
	end
	
	// Receiving start bit and checking its validity
	if (state == 1) begin
		osc <= osc + 1;
		osb <= osb + in;
		if (osc == ob-1) begin
			if (~arb) begin
				state <= state + 1;
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
		if (osc == ob-1) begin
			state <= state + 1;
			oub[7] <= (arb);
			oub[6:0] <= oub[7:1];
			osb <= 0;
			osc <= 0;
		end
	end

	// While receiving stop bit, out is pushed and dr asserted 
	// Stop part is cut short to 2 clock cycles in case receiver lags
	// behind the transmitter.
	if (state >= 10) begin
		osc <= osc + 1;
		if (osc == 0) out <= oub;
		if (osc == 1) state <= 0;
	end
end

// Data Ready
always @ (negedge clk, posedge dr_rst)
begin
	if (dr_rst) dr <= 0;
	else if (state >= 10 && osc == 1) dr <= 1;
end
endmodule

// Unbuffered UART Receiver without oversampling
// by Tomek Szczęsny 2024
//
// A simplified, lightweight UART RX that has no tolerance for clock errors.
// Designed to facilitate internal communication within FPGA,
// thus using the same clock source as the transmitter.
// clk_out pulse lasts for the duration of the stop bit.
//
//             +------------------+
//      in --->|                  |===> out[8]
//             |    uart_rx_no    |
//     clk --->|                  |---> clk_out
//             +------------------+
//
// Parameters: 
// None.
//
// Ports:
// clk		- a receiver clock input. Must be the same as TX clk.
// in		- UART input
// out[8] 	- 1-byte wide output register with received data
// clk_out	- Sends short positive pulse when out[8] is updated
//
//

module uart_rx_no(
	input wire clk,
	input wire in,
	output reg [7:0] out = 0,
	output reg clk_out = 0
);

reg [6:0] oub;			// Output buffer
reg [3:0] state = 2;		// Receiver machine state
// 0		The last data bit
// 1		Stop Bit
// 2		Idle / Start Bit
// 9 - 15	Data bits [0:6]
// Illegal states are not handled.

always @(posedge clk)
begin
	// Waiting for a start bit (State 2)
	if (~state[3] && state[1]) begin
		if (in == 0) begin		// Start bit has been received
			state <= 9;
		end
	end
	else state <= state + 1;
	
	// Data bits (States 9 - 15)
	if (state[3]) begin
		oub[6] <= in;
		oub[5:0] <= oub[6:1];
	end

	// The last bit (State 0)
	if (~state[3] && ~state[1] && ~state[0]) begin
		out[7] <= in;
		out[6:0] <= oub;
	end

	// Stop bit (State 1)
	clk_out <= (~state[3] && state[0]);
end

endmodule
`endif
