// SPI Slave Interface
// by Tomek Szczęsny 2024
//
// This interface reads data from MOSI pin and writes data to MISO pin.
// Internal ports are parallel, thus it also acts as a serdes.
// This interface currently support SPI mode 0 only (0,0).
//
//             +------------------+
//    MOSI --->|                  |===> out[n]
//    SCLK --->|     spi_slave    |---> clko
//     nCS --->|                  |<--- zo
//    MISO <---|                  |<=== in[n] 
//             +------------------+
//
// Parameters: 
// n		- bit width of the interface (8)
//
// Ports:
// MOSI		- Master Out, Slave In
// MISO		- Master In, Slave Out
// SCLK		- Serial Clock, provided by SPI bus master
// nCS		- Chip Select, resets and activates this module (Active Low)
// out[n]	- Parallel output with recived MOSI data
// in[n]	- Parallel input for MISO data to be sent
// clko		- Sends a positive pulse when out[n] is valid
// zo		- MISO buffer disable (goes into Hi-Z state)
//
// Notes:
// 1. In idle state (nCS=1) 'MISO' is forced to float regardless of 'zo'
// 2. In idle state (nCS=1) 'clko' is kept low
// 3. 'out[n]' is valid *only* when 'clko' is high
// 4. 'in[n]' and 'zo' are latched on the falling edge of 'clko'
// 5. 'clko' lasts only a half of the SCLK period
// 6. By convention, MSB is transmitted first
// 7. At least MISO must be a physical SB_IO pin (not the Global Buffer)
//

`ifndef _spi_slave_v_
`define _spi_slave_v_

module spi_slave(
	input wire MOSI,
	input wire SCLK,
	input wire nCS,
	output wire MISO,
	output reg [n-1:0] out = 0,
	output wire clko,
	input wire zo,
	input wire [n-1:0] in
);

parameter n = 8;

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
