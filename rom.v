`default_nettype none

module rom (
	clk,
	ren,
	raddr,
	rdata
);

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;
parameter NUM_WORDS = 256;

input clk, ren;
input [ADDR_WIDTH-1:0] raddr;
output reg [DATA_WIDTH-1:0] rdata;

// Actual data storage
reg [DATA_WIDTH-1:0] mem [0:NUM_WORDS-1];

initial begin
	$readmemh("test_prog.mem", mem);
end

always @(posedge clk) begin
	if (ren)
		rdata <= mem[raddr];
end

endmodule
