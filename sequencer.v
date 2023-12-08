//
// Programmable sequence generator
// by Tomek Szczesny 2023
//
// This is a generator of arbitrary, synchronous bit sequences.
// This may be used for hard-coding complex or repeatable patterns.
// During operation, it reads instructions from ROM and executes them.
//
// It is possible to alter execution order by forcing a program counter jump.
// This way, many procedures can be stored and called by external logic.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// List of all valid opcodes in ROM
// Binary formats for default module parameters.
//
// x - ignored
// D - real time output data (updated on each clock cycle)
// d - additional output data
// n - param
//
// 000dddddDDDD	STOP	Update output register and stop. Sequencer may only be 
// 			resumed through externaly commanded jump
// 001dddddDDDD OUT	Update output register
// 010nnnnnDDDD	LDI	Load immediate value "n" to register A
// 011nnnnnDDDD	LDIM	Load immediate value "n" multiplied by 64 to register A
// 100nnnnnDDDD	JMP	Stores incremented address in register A and performs
// 			absolute jump to address "n"
// 101nnnnnDDDD	DECJNZ	Decrement value of register A; jump to address "n" if A!=0
// 110dddddDDDD	RET	Update output register and return (jump to address in register A)
// 111xxxxxxxxx		Reserved
//
//
// Notes:
// 1. The opcode length is not fixed. Opcode width and "D" width are module
// parameters, which will directly affect the width of "n" and "d" fields.
// These cannot be narrower than 1 bit.
// 2. Register A has the capacity to store the maximum LDIM value.
// 3. "data" output is "d" and "D" fields combined. 
// 4. If "n" fields are shorter than available addresses, they are treated
// as the most significant bits of the address, and padded with zeroes.
// 5. All opcodes execute in one clock cycle. 
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// Simple example: Stepper Motor Driver, Full Step, 5 rotations.
// This examples uses 6 words in single 256-word ROM block. 
//
//	LDI 5		
// loop:
// 	OUT		4'b1001
// 	OUT		4'b1100
// 	OUT		4'b0110
//	DECJNZ	loop 	4'b0011
//	STOP 		4'b0000
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
//            +------------------+
//            |                  |
//     in --->|      clkdiv      |---> out
//            |                  |
//            +------------------+
//
// Parameters:
// divider - a clock divider.
//
// Ports: 
// in	- Input
// out	- Output
//
`ifndef _clkdiv_v_
`define _clkdiv_v_

module clkdiv(
	input wire in,
	output reg out = 0
);
parameter divider = 2;

reg [$clog2(divider-1):0] clkdiv = 0;

always@(posedge in)
begin
	if (clkdiv >= (divider - 1)) begin
		clkdiv <= 0;
		out <= 1;
	end else begin
		clkdiv <= clkdiv + 1;
		out <= (clkdiv + 1 < (divider/2));
	end
end

endmodule

`endif
