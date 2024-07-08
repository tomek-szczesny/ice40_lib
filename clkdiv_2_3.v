//
// A high performance clock divider, by 2 or 3
// by Tomek Szczesny 2024
//
// clkdiv_2_3 divides the frequency of input clock signal by either 2 or 3,
// depending on the polarity of input signal.
// Its primary application is early stages of frequency division.
//
// This divider transitions with no glitches.
// The output signal duty cycle is near 50% if the input duty cycle is also 50%.
// In and out posedges are in sync.
//
//            +----------------+
//    sel --->|                |
//     in --->|   clkdiv_2_3   |---> out
//            |                |
//            +----------------+
//
// Parameters:
// None.
//
// Ports: 
// sel	- Division select (2 when low, 3 when high)
// in	- Input
// out	- Output
//
`ifndef _clkdiv_2_3_v_
`define _clkdiv_2_3_v_

module clkdiv_2_3(
	input wire sel,
	input wire in,
	output wire out
);

reg [1:0] ne = 0;
reg pe = 0;
reg rsel = 0;

always@(negedge in)
begin
	if (ne == 2'b00) 
	begin
		rsel <= sel;
		ne <= {sel, 1'b1};
	end
	if (ne == 2'b01) ne <= 2'b00;
	if (ne == 2'b11) ne <= 2'b01;
	if (ne == 2'b10) ne <= 2'b00;
end

always@(posedge in)
begin
	pe <= ne[0];
end

assign out = pe && (ne[0] || ~rsel);

endmodule

`endif
