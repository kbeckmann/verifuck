// Based on https://www.reddit.com/r/yosys/comments/5aqzyr/can_i_write_behavioral_verilog_that_infers_ice40/d9imje6/
`default_nettype none

module blockram (
	input                       clk,
	input                       wen,
	input                       ren,
	input      [ADDR_WIDTH-1:0] waddr,
	input      [ADDR_WIDTH-1:0] raddr,
	input      [DATA_WIDTH-1:0] wdata,
	output reg [DATA_WIDTH-1:0] rdata
);

parameter DATA_WIDTH = 8;
parameter ADDR_WIDTH = 8;
parameter NUM_WORDS  = 256;
parameter HEXFILE    = "";

// Actual data storage
reg [DATA_WIDTH-1:0] mem [0:NUM_WORDS-1];

// Make the first 4 words visible in gtkwave
wire [DATA_WIDTH-1:0] mem0 = mem[0];
wire [DATA_WIDTH-1:0] mem1 = mem[1];
wire [DATA_WIDTH-1:0] mem2 = mem[2];
wire [DATA_WIDTH-1:0] mem3 = mem[3];

generate
	if (HEXFILE != 0) begin
		initial	$readmemh(HEXFILE, mem);
	end else begin
		integer i;
		initial begin
			for (i = 0; i < NUM_WORDS; i = i + 1)
				mem[i] = {DATA_WIDTH{0}};
		end
	end
endgenerate

always @(posedge clk) begin
	if (wen)
		mem[waddr] <= wdata;
	if (ren)
		rdata <= mem[raddr];
end

`ifdef	FORMAL

	reg	f_past_valid;
	initial	f_past_valid = 1'b0;
	always @(posedge clk)
		f_past_valid <= 1'b1;

	always @(posedge clk) begin
		if (f_past_valid &&
			$past(wen)
		)
			assert(mem[$past(waddr)] == $past(wdata));

		// I am not entirely sure why this works..
		// I assumed I had to use the following:
		// 	 assert(rdata == $past(mem[$past(raddr)]));
		// since raddr can change after the read is done... Confused!
		if (f_past_valid &&
			$past(ren)
		)
			assert(rdata == $past(mem[raddr]));
	end

`endif

endmodule
