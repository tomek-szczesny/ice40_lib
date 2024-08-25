// SPI Slave Interface Submodule
// by Tomek Szczęsny 2024
//
// This submodule is a register that can be read by the SPI master,
// and written to by external logic.
//
//
//
//         + - - - - - - +                   +-------------------+
//  MOSI ->              |===> out[n]        |                   |
//  SCLK ->|  spi_slave   ---> strobe  ----->|  spi_slave_reg_r  |<-- clk
//   nCS ->              |===> addr[n] =====>|                   |
//  MISO <-|              <=== in[n] (OR)<===|                   |<== d[n]
//                       |<--- zo (AND)<-----|                   |
//         + - - - - - - +                   +-------------------+
//
// Parameters: 
// a[n]		- The address, or MSBs of reg set address (0)
// n		- bit width of the interface (8)
//
// Ports:
// strobe	- Strobe input
// addr[n]	- Address input
// in[n]	- Data output       (must be ORed with the others)
// zo		- MISO Hi-Z disable (must be ANDed with the others)
// d[n]		- Data latch input
// clk		- Data latch clock, posedge sensitive
//
//

`ifndef _spi_slave_reg_r_v_
`define _spi_slave_reg_r_v_

module spi_slave_reg_r(
	input wire strobe,
	input wire [n-1:0] addr,
	output wire [n-1:0] in,
	output wire zo,
	input wire [n-1:0] d,
	input wire clk
);

parameter n = 8;
parameter [n-1:0] a = 0;

reg [n-1:0] buffer;

always@(posedge clk)
begin
	buffer <= d;
end

always@(strobe, d)
begin
	if ((addr == a) && strobe)
	begin
		in <= d;
		zo <= 0;
	end else begin





reg [$clog2(n)-1:0] cnt = 0;		// Bit counter
reg [n-1:0] inr = 0;			// Input latch
reg zor = 1;
wire miso_z;				// Enable Hi-Z on MISO pin
assign miso_z = nCS || zor;
wire iclk;				// Internal clock, carries through nCS negedge
assign iclk = nCS || SCLK;

assign clko = SCLK && (cnt == 0) && ~nCS;

// Physical MISO output
SB_IO #(
    .PIN_TYPE(6'b1010_01),		// Pin output with enable
    .PULLUP(1'b0)
) miso_sb_io (
    .D_OUT_0(inr[n-1]),
    .PACKAGE_PIN(MISO),
    .OUTPUT_ENABLE(~miso_z),
);

// Latching and shifting input data
always@(negedge iclk, posedge nCS)
begin
	if (nCS) begin
		cnt <= 0;
	end else begin
		if (cnt == 0)
		begin	
			cnt <= (n-1);
			inr[n-1:0] <= in[n-1:0];
			zor <= zo;
		end else begin
			cnt <= (cnt-1);
			inr[n-1:1] <= inr[n-2:0];
			inr[0] <= in[0];
		end
	end
end

// Reading MOSI 
always@(posedge SCLK, posedge nCS)
begin
	if (nCS) begin
		out <= 0;
	end else begin
		out[n-1:1] <= out[n-2:0];
		out[0] <= MOSI;
	end
end

endmodule

`endif
