// SDRAM commands:
// RAS CAS WE AP
// Notes:
// 1. BA is common for BA1 and BA0.
// 2. AP shares physical pin with A10.
`define SDR_NOP  4'b1110	// No Operation
`define SDR_BST  4'b1100	// Burst Stop
`define SDR_RD   4'b1010	// Read
`define SDR_RDA  4'b1011	// Read with auto precharge
`define SDR_WR   4'b1000	// Write
`define SDR_WRA  4'b1001	// Write with auto precharge
`define SDR_ACT  4'b0110	// Bank Activate
`define SDR_PRE  4'b0100 	// Precharge select bank
`define SDR_PALL 4'b0101 	// Precharge all banks
`define SDR_MRS  4'b0000	// Mode Register Set
