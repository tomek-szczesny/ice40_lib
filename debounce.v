//
// Button debouncer
// by Tomek Szczesny 2023
//
// This module acts as a crude, simple low pass filter, which in particular is
// useful for button debouncing. Without it, button presses are often
// registered more than once.
// It requires a clock. Any clock will do, the slowest one available in the
// system usually will suffice.
// Debounce period of ~10ms is more than enough in most applications.
//
//            +----------------+
//    clk --->|                |
//     in --->|    debounce    |---> out
//            |                |
//            +----------------+
//
// Parameters:
// n - filter length (in clk periods) (1024)
//
// Ports: 
// clk - clock input
// in	- Input
// out	- Output
//
`ifndef _debounce_v_
`define _debounce_v_

module debounce(
	input wire in,
	input wire clk,
	output reg out = 0
);
parameter n = 1024;
localparam max = n-1;

reg [$clog2(n-1):0] ctr = 0;

always@(posedge clk)
begin
	if (ctr == 0)   out <= 0;
	if (ctr == max) out <= 1;

	if ( in & (ctr != max)) ctr <= ctr+1;
	if (~in & (ctr != 0  )) ctr <= ctr-1;
end

endmodule

`endif
