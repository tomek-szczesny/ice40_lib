//
// Programmable sequence generator
// by Tomek Szczesny 2023
//
// This is a generator of arbitrary, synchronous bit sequences.
// This may be used for hard-coding complex or repeatable patterns.
// During operation, it reads instructions from ROM and executes them.
//
// Instructions are specifically conceived to support looping and calling 
// subroutines. A stack is implemented to facilitate looping and control
// transfer.
// 
// The module supports externally commanded jumps when it's in STOP state.
// This allows for programming multiple subroutines in a single ROM, 
// called by external logic, and protects against interrupting unfinished
// procedures. 
// FIFO can be used for scheduling tasks with no additional logic.
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// List of all valid opcodes in ROM
// Binary formats for default module parameters.
//
// x - ignored
// D - real time output data (updated on each clock cycle)
// d - additional output data
// n - parameters
//
// 000dddddddddDDDD	STOP	Update output register and stop.
// 				Sequencer may only be resumed through
// 				externaly commanded jump
// 001dddddddddDDDD 	OUT	Update output register
// 011dddddddddDDDD	RET	Update output register and return 
// 				(jump to address popped from stack)
// 				If stack is empty, act like OUT.
// 010dddddddddDDDD	POP	Update output register and remove a word from stack
// 110nnnnnnnnnDDDD 	PUSHI	Push immediate value "n" on stack
// 111nnnnnnnnnDDDD	DECJNZ	Decrement value on top of stack; 
// 				jump to address "n" if stack top !=0
// 				Otherwise pop stack and continue.
// 101nnnnnnnnnDDDD 	JMP	Performs absolute jump to address "n"
// 100nnnnnnnnnDDDD	CALL	Pushes incremented address on stack 
// 				and performs absolute jump to address "n"
//
//
// Notes:
// 1. The opcode length is not fixed. Opcode width and "D" field width are module
// parameters, which will directly affect the width of "n" and "d" fields.
// These cannot be narrower than 1 bit.
// 2. Stack has the bit width of "n" field.
// 3. Stack width limits the ROM address space (to support CALL).
// 4. "data_o" output register is "d" and "D" fields combined. 
// 5. All opcodes execute in one clock cycle. 
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
// Simple example: Stepper Motor Driver, Full Step, 5 rotations.
// This examples uses 6 words in a single 256-word ROM block. 
//
//	PUSHI 5		4'b0000
// loop:
// 	OUT		4'b1001
// 	OUT		4'b1100
// 	OUT		4'b0110
//	DECJNZ	loop 	4'b0011
// 	OUT		4'b1001
//	STOP 		4'b0000
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
//
//                              +---------------------+
//                    clk ----->|                     |
//   + - - - - +                |      sequencer      |===> data_o[2^(ocw-3)]
//              => addr[2^aw] =>|                     |
//   |  fifo   |---> jump ----->|                     |===> pc[2^aw]
//                              |  +-----+ +-------+  |
//   |   aw    |                |  | rom | | stack |  |---> stop
//              <--- ~stop      |  +-----+ +-------+  |
//   + - - - - +                +---------------------+
//
// Parameters:
// ocw		- Total opcode width, ocw>=(3+1+ddw) (16)
// ddw		- Width of real time data output, 0=<ddw<(ocw-3-1) (4)
// program	- A bit stream describing behavior of this sequencer (STOP)
// plen		- program length in opcodes (128)
// std		- stack depth (256)
//
// LocalParams:
// aw		- Program memory address width = clog2(plen).
// sw		- Stack width = ocw-ddw-3
//
// Ports: 
// clk		- Clock input, everything is posedge triggered
// addr[alen]	- Input for address, for externally forced jump
// jump		- When "1", the state machine will unconditionally jump to
// 		  address "addr". It does not ovverride any other functions of
// 		  currently processed opcode.
// data_o[...]	- User data output, updated through sequencer opcodes
// pc[2^aw]	- Current Program Counter address
// stop		- Positive when program executes STOP in a loop.
//
// Notes:
// 1. Physical ROM width is equal to ocw, and stack width is sw.
// This is strongly recommended to keep stack width at or below 16,
// and depth at 256. This will reduce stack to a single Block RAM cell. 
// 2. Because iceRAM blocks cannot initialize their first address, PC starts
// at address "1". Thus the first ROM opcode will be ignored, but nevertheless 
// must be specified by the designer. 
//
`ifndef _sequencer_v_
`define _sequencer_v_

`include "rom.v"
`include "stack.v"

`define SEQ_STOP   3'b000
`define SEQ_OUT    3'b001
`define SEQ_RET    3'b011
`define SEQ_POP    3'b010
`define SEQ_PUSHI  3'b110
`define SEQ_DECJNZ 3'b111
`define SEQ_JMP    3'b101
`define SEQ_CALL   3'b100

module sequencer(
	input wire clk,
	input wire [aw-1:0] addr,
	input wire jump,
	output reg [ocw-4:0] data_o,
	output wire [aw-1:0] pc,
	output wire stop
);
parameter ocw  = 16;
parameter ddw  = 4;
parameter plen = 128;
parameter [0:ocw*plen-1] program = 0;
parameter std = 256;
localparam aw = $clog2(plen);
localparam sw = ocw-ddw-3;

// Program Counter
reg [aw-1:0] pcr;
initial pcr = 1;
// Next PC position
reg [aw-1:0] pcrn;
// Misc
wire [aw-1:0] pcrp1;
assign pcrp1 = pcr + 1;
assign pc = pcr;

// Next data_o
reg [ocw-4:0] data_on;

// Current opcode
wire [ocw-1:0] oc;
wire [2:0] oc_cmd;
wire [sw-1:0] oc_param;
wire [ddw-1:0] oc_dd;
assign oc_cmd = oc[ocw-1:ocw-3];
assign oc_param = oc[ocw-4:ddw];
assign oc_dd = oc[ddw-1:0];

// Output signal "stop"
assign stop = (oc_cmd == `SEQ_STOP);

// Stack input
reg [sw-1:0] st_i;
// Stack output
wire [sw-1:0] st_o;
// Stack command
reg [2:0] st_c;
// Stack status 
wire [3:0] st_s;

// Stack output interpreted as ROM address
wire [aw-1:0] st_o_addr;
assign st_o_addr = st_o[aw-1:0];

// OC Param interpreted as ROM address
wire [aw-1:0] oc_param_addr;
assign oc_param_addr = oc_param[aw-1:0];



rom #(
	.m(plen),
	.n(ocw),
	.data({program}),
	.content_size(plen)
) seq_rom (
	.clk(clk),
	.address(pcrn),
	.data_o(oc)
);

stack #(
	.m(std),
	.n(ocw-ddw-3)
) seq_stack (
	.clk(clk),
	.data(st_i),
	.data_o(st_o),
	.command(st_c),
	.status(st_s)
);

// Asynchronous stuff - setting up things for next clock posedge
// TODO: Break it down into separate "always" statements.
always@(oc, oc_cmd, oc_dd, oc_param, oc_param_addr, jump, pcr, pcrp1, data_o, st_o_addr)
begin
	// There are only two cases when stack is written to:
	// PUSHI and CALL. In other cases stack input is ignored.
	// PUSHI: 110; CALL: 100
	if (oc_cmd[1]) begin	// PUSHI
		st_i <= oc_param;
	end else begin		// CALL
		st_i <= pcrp1;
	end

	// All commands update "D" output
	data_on[ddw-1:0] <= oc_dd;

	// Commands "0xx" update "d" output
	if (~oc[ocw-1]) begin
		data_on[ocw-4:ddw] <= oc_param;
	end else begin
		data_on[ocw-4:ddw] <= data_o[ocw-4:ddw];
	end

	// Determining the stack command
	case (oc_cmd)
		`SEQ_STOP:  st_c = `STK_NOP;
		`SEQ_OUT:   st_c = `STK_NOP;
		`SEQ_RET:   st_c = `STK_POP;	// Shouldn't matter if empty 
		`SEQ_POP:   st_c = `STK_POP;
		`SEQ_PUSHI: st_c = `STK_PUSH;
		`SEQ_DECJNZ: begin
			if (st_o < 2) begin
				st_c = `STK_POP;
			end else begin 
				st_c = `STK_DEC;
			end
		end
		`SEQ_JMP:  st_c = `STK_NOP;
		`SEQ_CALL: st_c = `STK_PUSH;
	endcase

	// Figuring out the next PC value
	if (jump && stop) pcrn <= addr;
	else begin
		case (oc_cmd)
			`SEQ_STOP: begin
				pcrn <= pcr;
			end
			`SEQ_OUT: begin
				pcrn <= pcrp1;
			end
			`SEQ_RET: begin
				if (st_s[0]) pcrn <= st_o_addr;
				else pcrn <= pcrp1;
			end
			`SEQ_POP: begin
				pcrn <= pcrp1;
			end
			`SEQ_PUSHI: begin
				pcrn <= pcrp1;
			end
			`SEQ_DECJNZ: begin
				if (st_o < 2) begin
					pcrn <= pcrp1;
				end else begin 
					pcrn <= oc_param_addr;
				end
			end
			`SEQ_JMP: begin
				pcrn <= oc_param_addr;
			end
			`SEQ_CALL: begin
				pcrn <= oc_param_addr;
			end
		endcase
	end
end

// Synchronous stuff
always@(posedge clk)
begin
	data_o <= data_on;
	pcr <= pcrn;

end

endmodule

`endif
