// General purpose stack
// by Tomek Szczęsny 2023
//
// Also known as LIFO/FILO buffer.
//
// Supports a few extra stack top manipulation functions, but can also be used
// as a regular stack with "store" and "load" functions only.
// Top of the stack is always exposed on "data_o" output.
//
// Uses iCE40 4kb RAM blocks. For the best results, set buffer width and depth
// so the total capacity is a multiple of 4096b.
//
//             +-----------------+
//     clk --->|                 |
//             |                 |              
// data[n] ===>|      stack      |===> data_o[n]
//             |                 |
// command[3]=>|                 |===> status[4]
//             +-----------------+
//                             
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// Commands:
//
// 000	NOP	Do nothing
// 001	PUSH	Add "data" to stack
// 010	POP	Remove top element from stack
// 011	LDI	Replace top stack element with "data"
// 100	INC	Increment stack top value
// 101	DEC	Decrement stack top value
// 110	USR1	Do not use (or implement your own function)
// 111	USR2	Do not use (or implement your own function)
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//
// Parameters: 
// n - bit width of a stack. 2, 4, 8, 16. (8)
// m - stack depth, must be a power of 2. (512)
//
// Ports:
// clk		- Clock input. Commands are executed on posedge.
// data[n] 	- Data input for commands PUSH, LDI
// data_o[n]	- An output exposing stack top at all times
// status[4]	- Stack status output:
// 			0000 - Stack empty (output invalid)
// 			0001 - <= 25% full
// 			0011 - <= 50% full
// 			0101 - <= 75% full
// 			0111 - < 100% full
// 			1111 -   100% full
//
// Note:
// The "n" parameter may actually be any value, but be mindful of the ice40
// RAM block design and possible unusable memory. 
// Certainly n=10 and m=2048 is possible and will glue five 4k blocks together.
// However the "m" parameter must always be the power of 2 due to module design
// choices.

`ifndef _stack_v_
`define _stack_v_

`define STK_NOP 3'b000
`define STK_PUSH 3'b001
`define STK_POP 3'b010
`define STK_LDI 3'b011
`define STK_INC 3'b100
`define STK_DEC 3'b101

module stack(
	input wire clk,
	input wire[n-1:0] data,
	input wire[2:0] command,
	output wire[n-1:0] data_o,
	output reg[3:0] status
);
parameter n = 8;
parameter m = 512;

// Actual Block RAM for the stack
reg [n-1:0] stack_buf [0:m-1];
// Top stack element kept in separate reg, to enable direct operations on it
reg  [n-1:0] top = 0;
assign data_o = top;
// Number of elements in stack
reg  [$clog2(m):0] top_lvl = 0;
// Precomputed values that are often used
wire [$clog2(m)  :0] tlp1;
wire [$clog2(m)-1:0] tlm1, tlm2;
assign tlp1 = top_lvl + 1;
assign tlm1 = top_lvl - 1;
assign tlm2 = top_lvl - 2;

// Status output
always@(top_lvl)
begin
	if      (top_lvl == 0)     status <= 4'b0000;
	else if (top_lvl <=   m/4) status <= 4'b0001;
	else if (top_lvl <= 2*m/4) status <= 4'b0011;
	else if (top_lvl <= 3*m/4) status <= 4'b0101;
	else if (top_lvl <    m  ) status <= 4'b0111;
	else                       status <= 4'b1111;	
end

// Command execution 
always @(posedge clk)
begin
	case (command)
	`STK_PUSH: begin
			if (~status[3]) begin
				stack_buf[tlm1] <= top;
				top <= data;
				top_lvl <= tlp1;
			end
		end
	
	`STK_POP: begin
			if (status[0]) begin
				top <= stack_buf[tlm2];
				top_lvl <= tlm1;
			end
		end
	
	`STK_LDI: begin
			if (status[0]) begin
				top <= data;
			end
		end
	
	`STK_INC: begin
			if (status[0]) begin
				top <= top + 1;
			end
		end
	
	`STK_DEC: begin
			if (status[0]) begin
				top <= top - 1;
			end
		end
	
	default: 	// NOP and unimplemented commands
			top <= top;	
	endcase
end

endmodule

`endif
