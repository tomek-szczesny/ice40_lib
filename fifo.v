// General purpose FIFO buffer
// by Tomek Szczęsny 2022
//
// Accepts and exposes data of fixed width at the other end.
// Both ends can be clocked independently.
//
// On each clk posedge, data[n] is stored in FIFO.
// On each clk_o posedge, data_o[n] is updated with the oldest stored value.
//
// Note that on startup, data_o[n] is invalid, and the first stored value has
// to be clocked out.
// ~status[0] indicates that there's nothing more to be clocked out. 
//
// If there is no data to be discarded, the output is undefined.
//
// Uses iCE40 4kb RAM blocks. For the best resuts, set buffer width and depth
// so the total capacity is a multiple of 4096b.
//
//             +------------------+
//     clk --->|                  |<--- clk_o
//             |                  |              
// data[n] ===>|       fifo       |===> data_o[n]
//             |                  |
//             |                  |===> status[4]
//             +------------------+
//                             
//
// Parameters: 
//
// n - bit width of a buffer. 2, 4, 8, 16. (8)
// m - buffer depth, must be a power of 2 and >=32. (512)
//
// Ports:
// clk		- a clock input. Posedge stores "data[n]".
// data[n] 	- Data input fetched at each "clk" posedge.
// clk_o	- Discards the oldest data on posedge (thus updates "data_o")
// data_o[n]	- An output exposing the oldest data stored in FIFO
// status[4]	- Buffer status output:
// 			0000 - Buffer empty (output invalid)
// 			0001 - 0 - 25% full
// 			0011 - 25 - 50% full
// 			0101 - 50 - 75% full
// 			0111 - 75 - 95% full
// 			1111 - 95 - 100% full
//
// Note:
// The "n" parameter may actually be any value, but be mindful of the ice40
// RAM block design and possible unusable memory. 
// Certainly n=10 and m=2048 is possible and will glue five 4k blocks together.
// However the "m" parameter must always be the power of 2 due to module design
// choices.

`ifndef _fifo_v_
`define _fifo_v_

module fifo(
	input wire clk,
	input wire clk_o,
	input wire[n-1:0] data,
	output reg[n-1:0] data_o,
	output reg[3:0] status
);
parameter n = 8;
parameter m = 512;

localparam w = $clog2(m);

// buf_t points at the next free cell
// buf_b points at the oldest data cell
// Both have one bit wider versions so buf_lvl actually can count up to "m".
// As a result, MSB of buf_lvl indicates full buffer.

reg  [w:0] buf_top = 0;
reg  [w:0] buf_bot = 0;
wire [w-1:0] buf_t;
wire [w-1:0] buf_b;
wire [w:0] buf_lvl;
assign buf_t = buf_top[w-1:0];
assign buf_b = buf_bot[w-1:0];
assign buf_lvl = (buf_top - buf_bot);


reg [n-1:0] fifo_buf [0:m-1];

// Status output
always@*
begin
	status[0]   <= (buf_lvl != 0);
	status[1]   <= (buf_lvl[w-2] || buf_lvl[w]);
	status[2]   <= (buf_lvl[w-1] || buf_lvl[w]);
	status[3]   <= (&(buf_lvl[w-1:w-4]) || buf_lvl[w]);
end

// Data input
always @(posedge clk)
begin
	if(buf_lvl < m) begin
		fifo_buf[buf_t] <= data;
		buf_top <= buf_top + 1;
	end
end

// Data output
always @(posedge clk_o)
begin
	if (buf_lvl != 0)
	begin
		buf_bot <= buf_bot + 1;
		data_o <= fifo_buf[buf_b];
	end
end

endmodule

// General purpose FIFO buffer with clock enable signals
// by Tomek Szczęsny 2024
//
// Same as before, but can work with continuous clocks and clock enable
// signals instead.
//
//             +------------------+
//     clk --->|                  |<--- clk_o
//     cke --->|                  |<--- cke_o    
// data[n] ===>|     fifo_cke     |===> data_o[n]
//             |                  |
//             |                  |===> status[4]
//             +------------------+
//                             
//
// Parameters: 
//
// n - bit width of a buffer. 2, 4, 8, 16. (8)
// m - buffer depth, must be a power of 2 and >=32. (512)
//
// Ports:
// clk		- a clock input. Posedge stores "data[n]".
// cke		- Clock Enable for clk
// data[n] 	- Data input fetched at each "clk" posedge.
// clk_o	- Discards the oldest data on posedge (thus updates "data_o")
// cke_o	- Clock Enable for clk_o
// data_o[n]	- An output exposing the oldest data stored in FIFO
// status[4]	- Buffer status output:
// 			0000 - Buffer empty (output invalid)
// 			0001 - 0 - 25% full
// 			0011 - 25 - 50% full
// 			0101 - 50 - 75% full
// 			0111 - 75 - 95% full
// 			1111 - 95 - 100% full
//
// Note:
// The "n" parameter may actually be any value, but be mindful of the ice40
// RAM block design and possible unusable memory. 
// Certainly n=10 and m=2048 is possible and will glue five 4k blocks together.
// However the "m" parameter must always be the power of 2 due to module design
// choices.

module fifo_cke(
	input wire clk,
	input wire cke,
	input wire clk_o,
	input wire cke_o,
	input wire[n-1:0] data,
	output reg[n-1:0] data_o,
	output reg[3:0] status
);
parameter n = 8;
parameter m = 512;

localparam w = $clog2(m);

// buf_t points at the next free cell
// buf_b points at the oldest data cell
// Both have one bit wider versions so buf_lvl actually can count up to "m".
// As a result, MSB of buf_lvl indicates full buffer.

reg  [w:0] buf_top = 0;
reg  [w:0] buf_bot = 0;
wire [w-1:0] buf_t;
wire [w-1:0] buf_b;
wire [w:0] buf_lvl;
assign buf_t = buf_top[w-1:0];
assign buf_b = buf_bot[w-1:0];
assign buf_lvl = (buf_top - buf_bot);


reg [n-1:0] fifo_buf [0:m-1];

// Status output
always@*
begin
	status[0]   <= (buf_lvl != 0);
	status[1]   <= (buf_lvl[w-2] || buf_lvl[w]);
	status[2]   <= (buf_lvl[w-1] || buf_lvl[w]);
	status[3]   <= (&(buf_lvl[w-1:w-4]) || buf_lvl[w]);
end

// Data input
always @(posedge clk)
begin
	if((buf_lvl < m) && cke) begin
		fifo_buf[buf_t] <= data;
		buf_top <= buf_top + 1;
	end
end

// Data output
always @(posedge clk_o)
begin
	if ((buf_lvl != 0) && cke_o)
	begin
		buf_bot <= buf_bot + 1;
		data_o <= fifo_buf[buf_b];
	end
end

endmodule
// General purpose FIFO buffers
// by Tomek Szczęsny 2024
//
// A multiple FIFO implementation, with common input and output ports.
// This is intended for rearranging data using reduced number of Block RAM
// instances.
//
// The 'fifo' is divided into a number of equally sized sections, each with
// their own buffer state counters. 
// Input data is written into one or more locations indicated by the 
// input address vector. 
// Data output is clocked independently by the data consumer.
// Obviously only one data address can be read at the same time, so the output
// address is given in a binary format.
//
// Some write operations may take more than one clock cycle, so Block RAM and
// internal state machine have their own clock source, possibly much faster than
// input strobes.
// This also requires "ready" output for input RAM port, to notify the data
// source that the internal state machine had finished the job.
//
// Output port has no speed restrictions as it works independently 
// and can only provide one fifo word per each clock cycle.
//
// Buffer statuses are given as numerical values for each subbuffer
// independently.
//
// If there is no data to be discarded, the output is undefined.
//
// Uses iCE40 4kb RAM blocks. For the best resuts, set buffer dimensions
// so the total capacity is a multiple of 4096b.
//
//               +-----------------+
//       clk --->|                 |<--- clk_o
//      rdy  <---|                 |             
//   data[n] ===>|   fifo_multi    |===> data_o[n]
//   addr[o] ===>|                 |<=== addr_o[log2(o)]
//     latch --->|                 |===> status[log2(o)*log2(m)]
//               +-----------------+
//                             
//
// Parameters: 
//
// n - bit width of a buffer. 2, 4, 8, 16. (8)
// m - buffer depth, must be a power of 2 and >=32. (64)
// o - number of sub-buffers, must be a power of 2 and >= 2 (8)
//
// Ports:
// clk		- an input port clock input. Runs internal input state machine.
// rdy		- an output indicating that the internal state machine is idle
// latch	- an input signaling the state machine to latch "data" and "addr"
// data[n] 	- Data input fetched at "latch" posedge.
// addr[o]	- an input vector for indicating target subbuffers for "data"
//
// clk_o	- Updates data_o with the oldest data stored in addr_o
// data_o[n]	- An output exposing the oldest data stored in FIFO subbuffer
// addr_o[log2o]- An input for selecting data output subbuffer
// status[many]	- Buffer status outputs. Presents levels of each buffer.
//
//
// Note:
// The "n" parameter may actually be any value, but be mindful of the ice40
// RAM block design and possible unusable memory. 
// Certainly n=10 and m=2048 is possible and will glue five 4k blocks together.
// However the "m" parameter must always be the power of 2 due to module design
// choices.

module fifo_multi(
	input wire clk,
	output reg rdy, 
	input wire[n-1:0] data,
	input wire[o-1:0] addr,
	input wire latch,
	input wire clk_o,
	output reg[n-1:0] data_o = 0,
	input wire[$clog2(o)-1:0] addr_o,
	output wire[(w+1)*o-1:0] status
);
parameter n = 8;	// Word width
parameter m = 64;	// Word capacity of each subbuffer
parameter o = 8;	// Number of subbuffers

localparam w = $clog2(m);

reg [n-1:0] bdata;		// data buffer
reg [o-1:0] baddr;		// addr buffer
reg [$clog2(o+1)-1:0] is = 0;	// internal state
wire [$clog2(o)-1:0] iss;	// 0:o-1 - parsing input
assign iss = is [$clog2(o)-1:0];// o - idle

reg  [w:0] buf_top [o-1:0];
wire [w-1:0] buf_t [o-1:0];
reg  [w:0] buf_bot [o-1:0];
wire [w-1:0] buf_b [o-1:0];
wire [w:0] buf_lvl [o-1:0];

genvar i;
generate
	for (i=0; i<o; i=i+1)
	begin
		initial buf_top[i] = 0;
		assign buf_t[i] = buf_top[i][w-1:0];
		initial buf_bot[i] = 0;
		assign buf_b[i] = buf_bot[i][w-1:0];
		assign buf_lvl[i] = buf_top[i] - buf_bot[i];
		assign status[(w+1)*(i+1)-1:(w+1)*i] = buf_lvl[i];
	end
endgenerate	

reg [n-1:0] fifo_buf [0:(m*o)-1];

always @ (posedge latch)
begin

end

always @(posedge clk, posedge latch)
begin
	if (latch) 
	begin
		bdata <= data;
		baddr <= addr;
		rdy <= 0;
		is <= 0;
	end else begin
		if (baddr == 0)
		begin
			rdy <= 1;
			is <= o;
		end else begin
			is <= is + 1;
			baddr[o-2:0] <= baddr[o-1:1];
			baddr[o-1] <= 0;
			if (baddr[0] == 1 && buf_lvl[iss] < m) begin
				fifo_buf[{iss, buf_t[iss]}] <= bdata;
				buf_top[iss] <= buf_top[iss] + 1;
			end
		end
	end
end

// Data input

// Data output
always @(posedge clk_o)
begin
	if (buf_lvl[addr_o] != 0)
	begin
		buf_bot[addr_o] <= buf_bot[addr_o] + 1;
		data_o <= fifo_buf[{addr_o, buf_b[addr_o]}];
	end
end

endmodule

`endif
