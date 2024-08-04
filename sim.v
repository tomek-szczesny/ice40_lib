//
//// Simulation models library, for common ice40 primitives.
//// Without this, iverilog doesn't know what SB_LUT4 or SB_CARRY are.
// by Tomek Szczęsny 2024
//
`ifndef _sim_v_
`define _sim_v_

module SB_LUT4(
	input wire I0,
	input wire I1,
	input wire I2,
	input wire I3,
	output wire O
);
parameter LUT_INIT = 16'b0000_1111_1111_0000;

assign O = LUT_INIT[{I3, I2, I1, I0}];

endmodule

//////////

module SB_CARRY(
	input wire I0,
	input wire I1,
	input wire CI,
	output wire CO
);

assign CO = (I0 + I1 + CI) > 1;

endmodule

//////////

module SB_DFFR(output reg Q = 0, input wire C, input wire D, input wire R);
always@(posedge C, posedge R)
begin
	if (R) Q <= 0;
	else Q <= D;
end
endmodule

module SB_DFFS(output reg Q = 0, input wire C, input wire D, input wire S);
always@(posedge C, posedge S)
begin
	if (S) Q <= 1;
	else Q <= D;
end
endmodule

module SB_DFFSS(output reg Q = 0, input wire C, input wire D, input wire S);
always@(posedge C)
begin
	Q <= S ? 1 : D;
end
endmodule

module SB_DFFSR(output reg Q = 0, input wire C, input wire D, input wire R);
always@(posedge C)
begin
	Q <= R ? 0 : D;
end
endmodule

module SB_DFFER(output reg Q = 0, input wire C, input wire E, input wire D, input wire R);
always@(posedge C, posedge R)
begin
	if (R) Q <= 0;
	else if (E) Q <= D;
end
endmodule

module SB_DFFES(output reg Q = 0, input wire C, input wire E, input wire D, input wire S);
always@(posedge C, posedge S)
begin
	if (S) Q <= 1;
	else if (E) Q <= D;
end
endmodule

module SB_DFFESS(output reg Q = 0, input wire C, input wire E, input wire D, input wire S);
always@(posedge C)
begin
	if (E) Q <= S ? 1 : D;
end
endmodule

module SB_DFFESR(output reg Q = 0, input wire C, input wire E, input wire D, input wire R);
always@(posedge C)
begin
	if (E) Q <= R ? 0 : D;
end
endmodule

`endif
