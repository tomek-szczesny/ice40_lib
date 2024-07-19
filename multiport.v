// 4-pin multi-protocol port 
//
// by Tomek Szczęsny 2024
//
// This port is intended to be used with physical pins and may serve one of
// many functions. The port can dynamically change its mode or operation, or
// work with a fixed one (with unnecessary features optimized out, hopefully).
//
// Available modes of operation include UART with RTS/CTS, various GPIO and
// SPI modes, and there is still space for implementing more functionalities.
//
// The output is a UART stream clocked at the system clock rate, compatible
// with uart_matrix module inputs.
//
// 
//
// RTS/CTS signals have lost their original meaning and usually are cross
// connected, similarly to RX/TX wires.
// This implementation follows the RS-232-E definition.
//
// In essence, RTS signals readiness to receive data (Actually is called RTR).
// Most often it is dependent on the state of the internal buffer or processing
// unit. This signal can be used to slow down the transmitter if we can't keep
// up with receiving data.
//
// CTS is an input "Clear to Send", which means the receiver is ready to
// receive data. In practice this means that the transmitter should not
// transmit data when CTS is deasserted.
//
// When 'rtscts_en' is low, rts is always deasserted, and cts ignored.
//
// Note that the UART receiver will always receive incoming data, even if the
// buffer is full.
//
//                +-----------------+
//        clk --->|                 |
//         rx --->|                 |===> rx_data[8]
// tx_data[8] ===>|   uart_rtscts   |---> tx
//        cts --->|                 |---> rts
//  rtscts_en --->|                 |
//     rx_rdy --->|                 |---> rx_push
//     tx_rdy --->|                 |---> tx_pop
//                +-----------------+ 
//                            
// Parameters: 
// o		- Receiver oversampling factor, o > 3
//
// Ports:
// clk		- Receiver clock input (baudrate * o)
// rx, tx	- Receiver and Transmitter pins, typically physical pins
// rts		- Ready To Receive Output
// cts		- Clear To Send Input
// rtscts_en	- RTS/CTS enable
// tx_data[8]	- Internally latched tx parallel data input
// rx_data[8]	- Internally latched rx parallel data output
// rx_rdy	- Receiver Ready Input ("RX buffer isn't full yet")
// tx_rdy	- Transmission Ready Input ("We've got something to send")
// rx_push	- Generates a positive pulse to store rx_data byte in a FIFO
// tx_pop	- Generates a positive pulse to pop a value from a TX FIFO
//
// Note:
// 1. 'rx_push' and 'tx_pop' may be used for generating LED blinks
//
//
`ifndef _uart_rtscts_v_
`define _uart_rtscts_v_

`include "uart_rx.v"
`include "uart_tx.v"
`include "clkdiv.v"

module uart_rtscts(
	input wire clk,
	input wire rx,
	output wire tx,
	output wire rts,
	input wire cts,
	input wire [7:0] tx_data,
	output wire [7:0] rx_data,
	input wire rtscts_en,
	input wire rx_rdy,
	output wire rx_push,
	input wire tx_rdy,
	output wire tx_pop
);

parameter o = 4;

// Clock divider
wire tx_clk;
clkdiv #(o) tx_clkdiv (clk, tx_clk); 

// RTS/CTS
assign rts = ~(rtscts_en && rx_rdy);
wire tx_data_rdy;
assign tx_data_rdy = tx_rdy && ~(cts && rtscts_en);

// RX/TX instances

uart_rx #(o) uart_rx (
	.clk(clk), 
	.in(rx),
	.out(rx_data),
	.clk_out(rx_push)
);

uart_tx uart_tx (
	.clk(tx_clk), 
	.data_rdy(tx_data_rdy),
	.data(tx_data),
	.out(tx),
	.fetch(tx_pop)
);

endmodule

`endif
