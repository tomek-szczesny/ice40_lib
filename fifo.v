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
/*
	if      (buf_lvl == 0)     status <= 4'b0000;
	else if (buf_lvl <=   m/4) status <= 4'b0001;
	else if (buf_lvl <= 2*m/4) status <= 4'b0011;
	else if (buf_lvl <= 3*m/4) status <= 4'b0101;
	else if (buf_lvl <    m  ) status <= 4'b0111;
	else                       status <= 4'b1111;	
*/
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
/*
	if      (buf_lvl == 0)     status <= 4'b0000;
	else if (buf_lvl <=   m/4) status <= 4'b0001;
	else if (buf_lvl <= 2*m/4) status <= 4'b0011;
	else if (buf_lvl <= 3*m/4) status <= 4'b0101;
	else if (buf_lvl <    m  ) status <= 4'b0111;
	else                       status <= 4'b1111;	
*/
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
`endif
