// Based on https://www.reddit.com/r/yosys/comments/5aqzyr/can_i_write_behavioral_verilog_that_infers_ice40/d9imje6/

module blockram (
	clk, wen, ren,
	waddr, raddr,
	wdata, rdata
);

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;
parameter NUM_WORDS = 256;

input clk, wen, ren;
input [ADDR_WIDTH-1:0] waddr, raddr;
input [DATA_WIDTH-1:0] wdata;
output reg [DATA_WIDTH-1:0] rdata;

// Actual data storage
reg [DATA_WIDTH-1:0] mem [0:NUM_WORDS-1];

// Make the first 4 words visible in gtkwave
wire [DATA_WIDTH-1:0] mem0 = mem[0];
wire [DATA_WIDTH-1:0] mem1 = mem[1];
wire [DATA_WIDTH-1:0] mem2 = mem[2];
wire [DATA_WIDTH-1:0] mem3 = mem[3];

integer i;
initial begin
	for (i = 0; i < NUM_WORDS; i = i + 1)
		mem[i] = 0;
//	$readmemh("test_ram.mem", mem);
end

always @(posedge clk) begin
	if (wen)
		mem[waddr] <= wdata;
	if (ren)
		rdata <= mem[raddr];
end

endmodule
