//
// Clock gate
// by Tomek Szczesny 2023
//
// clkgate passes clock pulses reliably and without glitches.
// The gate input is probed only when in = 0.
//
//            +-----------------+
//            |                 |
//     in --->|     clkgate     |---> out
//   gate --->|                 |
//            +-----------------+
//
// Parameters:
// None.
//
// Ports: 
// in	- Clock input
// gate - Clock gate input
// out	- Clock output, active when gate = 1.
//
`ifndef _clkgate_v_
`define _clkgate_v_

module clkgate(
	input wire in,
	input wire gate,
	output wire out
);

reg latch;
assign out = (in & latch);

always@(negedge in)
begin
	latch <= gate;
end

endmodule

`endif
