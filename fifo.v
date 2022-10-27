// General purpose FIFO buffer
// by Tomek Szczęsny 2022
//
// Accepts and exposes data of fixed width at the other end.
// Both ends can be clocked independently.
//
// If there is no data to be discarded, the output is 0.
//
// Uses iCE40 4kb RAM blocks. For the best resuts, set buffer width and depth
// so the total capacity is a multiple of 4096b.
//
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
// n - bit width of a buffer. 2, 4, 8, or 16. (8)
// m - buffer depth, must be a power of 2. (512)
//
// Ports:
// clk		- a clock input. Posedge stores "data[n]".
// data[n] 	- Data input fetched at each "clk" posedge.
// clk_o	- Discards the oldest data on posedge (thus updates "data_o")
// data_o[n]	- An output exposing the oldest data stored in FIFO
// status[4]	- Buffer status output:
// 			0000 - Buffer empty
// 			0001 - <= 25% full
// 			0011 - <= 50% full
// 			0101 - <= 75% full
// 			0111 - < 100% full
// 			1111 -   100% full

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

initial data_o <= 0;

// buf_t points at the next free cell
// buf_b points at the oldest data cell
// Both have one bit wider versions so buf_lvl actually can count up to "m".

reg  [$clog2(m):0] buf_top = 0;
reg  [$clog2(m):0] buf_bot = 0;
wire [$clog2(m)-1:0] buf_t;
wire [$clog2(m)-1:0] buf_b;
wire [$clog2(m):0] buf_lvl;
assign buf_t = buf_top[$clog2(m)-1:0];
assign buf_b = buf_bot[$clog2(m)-1:0];
assign buf_lvl = (buf_top - buf_bot);

reg [n-1:0] fifo_buf [0:m-1];

// Status output
always@(buf_lvl)
begin
	if      (buf_lvl == 0)     status <= 4'b0000;
	else if (buf_lvl <=   m/4) status <= 4'b0001;
	else if (buf_lvl <= 2*m/4) status <= 4'b0011;
	else if (buf_lvl <= 3*m/4) status <= 4'b0101;
	else if (buf_lvl <    m  ) status <= 4'b0111;
	else                       status <= 4'b1111;	
end

// Data input
always @(posedge clk)
begin
	if(buf_lvl < m) begin
		fifo_buf[buf_t] <= data;
		buf_top <= buf_top + 1;
	end
end

always @(posedge clk_o)
begin
	if (buf_lvl > 0)
	begin
		data_o <= fifo_buf[buf_b];
		buf_bot <= buf_bot + 1;
	end
	else begin
		data_o <= 0;
	end
end

endmodule

`endif
