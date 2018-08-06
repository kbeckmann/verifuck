// Used https://github.com/jackcarrozzo/brainfuck-processor as a baseline

`default_nettype none

`define INCDP   ">"
`define DECDP   "<"
`define INCDATA "+"
`define DECDATA "-"
`define OUTONE  "."
`define INONE   ","
`define CONDJMP "["
`define JMPBACK "]"
`define ZERO    8'h00

module proc (
	prog_addr,	// out: program instruction address
	prog_ren,	// out: program read enable
	data_addr,	// out: data r/w address
	data_wen,	// out: data write enable
	data_ren,	// out: data read enable
	data_wval,	// out: data write value
	stdout,		// out: data out
	stdout_en,	// out: data out enable (will be toggled when there is data)
	data_rval,	// in:  data read value
	prog_rval,	// in:  program read value (next instruction to be executed)
	en,			// in:  enable. Low halts the processor
	clk,		// clock
	reset,		// reset, active low
	exception	// CPU raised an exception
);

parameter DATA_ADDR_WIDTH = 8;
parameter DATA_VALUE_WIDTH = 8;
parameter PROG_ADDR_WIDTH = 8;
parameter PROG_VALUE_WIDTH = 8;
parameter STACK_DEPTH = 8; // takes up a ton of LUTs

output reg [PROG_ADDR_WIDTH-1:0]	prog_addr = 0;
output reg							prog_ren = 0;
output reg [DATA_ADDR_WIDTH-1:0]	data_addr = 0;
output reg							data_wen = 0;
output reg							data_ren = 0;
output reg [DATA_VALUE_WIDTH-1:0]	data_wval = 0;
output reg [7:0]					stdout = 0;
output reg							stdout_en = 0;
output reg							exception = 0;

input [DATA_VALUE_WIDTH-1:0]		data_rval;
input [PROG_VALUE_WIDTH-1:0]		prog_rval;
input								en;
input								clk;
input								reset;

wire [DATA_VALUE_WIDTH-1:0] register = data_rval;

reg [PROG_ADDR_WIDTH-1:0] prog_stack [0:STACK_DEPTH-1];
reg [PROG_ADDR_WIDTH-1:0] stack_index = 0;

// Used for debugging, they are free when synthesized
wire [7:0] prog_stack_0 = prog_stack[0];
wire [7:0] prog_stack_1 = prog_stack[1];
wire [7:0] prog_stack_2 = prog_stack[2];
wire [7:0] prog_stack_3 = prog_stack[3];
wire [7:0] prog_stack_4 = prog_stack[4];
wire [7:0] prog_stack_5 = prog_stack[5];
wire [7:0] prog_stack_6 = prog_stack[6];
wire [7:0] prog_stack_7 = prog_stack[7];
wire [7:0] current_stack_ptr = prog_stack[stack_index];

integer i;
initial begin
	for (i = 0; i < STACK_DEPTH; i = i + 1)
		prog_stack[i] <= 0;
end

localparam STATE_STOP	= 0;
localparam STATE_RESET	= 1;
localparam STATE_IF		= 2;
localparam STATE_EX		= 3;
localparam STATE_MEM	= 4;
localparam STATE_WB		= 5;

reg [3:0] state = STATE_RESET;

always @(posedge clk) begin
	if (reset && en) begin
		state <= STATE_RESET;
		prog_addr <= 0;
		prog_ren <= 0;
		data_wen <= 0;
		data_ren <= 0;
		data_addr <= 0;
		stdout_en <= 0;
		exception <= 0;
	end else if (en) begin
		//$monitor("state=%d data_addr=%d data_rval=%d prog_addr=%d prog_rval=%d %c",
		//	state, data_addr, data_rval, prog_addr, prog_rval, prog_rval);

		case (state)
		STATE_STOP: begin
			prog_addr <= 0;
			prog_ren <= 0;
			data_wen <= 0;
			data_ren <= 0;
			data_addr <= 0;
			stdout_en <= 0;
		end
		STATE_RESET: begin
			prog_addr <= 0;
			prog_ren <= 1;
			data_wen <= 0;
			data_ren <= 0;
			data_addr <= 0;
			stdout_en <= 0;
			state <= STATE_IF;
		end
		STATE_IF: begin
			prog_ren <= 0;
			data_wen <= 0;
			data_ren <= 0;
			stdout_en <= 0;
			prog_addr <= prog_addr + 1;
			state <= STATE_EX;
		end
		STATE_EX: begin
			if (prog_rval == `INCDP) begin
				data_addr <= data_addr + 1;
			end else if (prog_rval == `DECDP) begin
				data_addr <= data_addr - 1;
			end else if (prog_rval == `INCDATA || prog_rval == `DECDATA || prog_rval == `OUTONE) begin
				data_ren <= 1;
			end else if (prog_rval == `JMPBACK) begin
				data_ren <= 1; // in order to check if data is 0
				// read current stack pointer
			end

			if ((prog_rval == `ZERO) ||
				(prog_rval == `DECDP && data_addr == 0) ||
				(prog_rval == `INCDP && data_addr == 2**DATA_ADDR_WIDTH - 1) ||
				(prog_rval == `CONDJMP && stack_index == STACK_DEPTH-1) ||
				(prog_rval == `JMPBACK && stack_index == 0)
			) begin
				state <= STATE_STOP;
			end else begin
				state <= STATE_MEM;
			end
		end
		STATE_MEM: begin
			// Buffer state for read.
			data_ren <= 0;
			state <= STATE_WB;
		end
		STATE_WB: begin
			// Buffer state for write.

			if (prog_rval == `INCDATA) begin
				data_wval <= data_rval + 1;
			end else if (prog_rval == `DECDATA) begin
				data_wval <= data_rval - 1;
			end else if (prog_rval == `OUTONE) begin
				stdout <= data_rval;
				stdout_en <= 1;
			end else if (prog_rval == `CONDJMP) begin
				// $monitor("{LOOP START storing @%d = %d+1}", stack_index, prog_addr);
				// Store where to jump back to (prog_addr points to the next instruction)
				prog_stack[stack_index] <= prog_addr;
				stack_index <= stack_index + 1;
			end else if (prog_rval == `JMPBACK) begin
				if (data_rval == 0) begin
					// $monitor("{LOOP END %d jmp->%d+1}", data_rval, prog_addr);
					stack_index <= stack_index - 1;
				end else begin
					// $monitor("{LOOP END %d jmp->%d}", data_rval, current_stack_ptr);
					prog_addr <= prog_stack[stack_index - 1];
				end
			end

			data_wen <= (prog_rval == `INCDATA || prog_rval == `DECDATA);
			prog_ren <= 1;
			data_ren <= 0;
			state <= STATE_IF;
		end
		default: begin
			// Illegal state, can't happen
		end
		endcase

	end else begin
		// CPU halted
	end
end

`ifdef FORMAL

integer clk_ticks = 0;
always @(posedge clk) begin
	clk_ticks <= clk_ticks + 1;

	if (reset == 0 && state != STATE_STOP) begin
		// Check that the state machine always changes states correctly
		if ($past(state) != state) begin
			if ($past(state) == STATE_IF) assert (state == STATE_EX);
			if ($past(state) == STATE_EX) assert (state == STATE_MEM);
			if ($past(state) == STATE_MEM) assert (state == STATE_WB);
			if ($past(state) == STATE_WB) assert (state == STATE_IF);
		end
		// if ($past(prog_addr) != prog_addr) assert(prog_addr == $past(prog_addr) + 1);
	end

	// Verify that executing < when data_addr == 0 leads to the STOP state
	if (clk_ticks > 3 &&
		$past(state) == STATE_EX &&
		$past(data_addr) == 0 &&
		$past(prog_rval, 2) == `DECDP &&
		$past(prog_rval, 1) == `DECDP
	)
		assert (state == STATE_STOP);

	// Verify that executing > when data_addr == DATA_ADDR_WIDTH**2-1 leads to the STOP state
	if (clk_ticks > 3 &&
		$past(state) == STATE_EX &&
		$past(data_addr) == DATA_ADDR_WIDTH**2-1 &&
		$past(prog_rval, 2) == `INCDP &&
		$past(prog_rval, 1) == `INCDP
	)
		assert (state == STATE_STOP);

	// Verify that executing ] when stack_index == 0 leads to the STOP state
	if (clk_ticks > 3 &&
		$past(state) == STATE_EX &&
		$past(stack_index) == 0 &&
		$past(prog_rval, 2) == `JMPBACK &&
		$past(prog_rval, 1) == `JMPBACK
	)
		assert (state == STATE_STOP);

	// Verify that executing [ when stack_index == STACK_DEPTH-1 leads to the STOP state
	if (clk_ticks > 3 &&
		$past(state) == STATE_EX &&
		$past(stack_index) == STACK_DEPTH-1 &&
		$past(prog_rval, 2) == `CONDJMP &&
		$past(prog_rval, 1) == `CONDJMP
	)
		assert (state == STATE_STOP);

end

`endif

endmodule
