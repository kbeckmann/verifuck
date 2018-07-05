// Used https://github.com/jackcarrozzo/brainfuck-processor as a baseline

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
	reset		// reset, active low
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
		prog_stack[i] = 0;
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

			if (prog_rval == `ZERO) begin
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

/*
		if (state == STATE_EX) begin
			if (prog_rval != `ZERO) begin
				state <= STATE_MEM;
			end else begin
				// Get stuck in STOP state forever
				state <= STATE_STOP;
			end

			if (prog_rval == `INCDATA || prog_rval == `DECDATA) begin
				data_wen <= 1;
			end else begin
				data_wen <= 0;
			end

			case (prog_rval)
				`INCDP: begin
					data_addr <= data_addr + 1;
				end
				`DECDP: begin
					data_addr <= data_addr - 1;
				end
				`INCDATA: begin
					data_wval <= register + 1;
				end
				`DECDATA: begin
					data_wval <= register - 1;
				end
				`OUTONE: begin
					stdout <= data_rval;
					stdout_en <= 1;
				end
				`INONE: begin
					//TODO
				end
				`CONDJMP: begin
					//$monitor("{LOOP START storing @%d = %d+1}", stack_index, prog_addr);
					prog_stack[stack_index] <= prog_addr + 1; // Store where to jump back to
					stack_index <= stack_index + 1;
				end
				`JMPBACK: begin
					if (register == 0) begin
						//$monitor("{LOOP END %d jmp->%d+1}", register, prog_addr);
						stack_index <= stack_index - 1;
						prog_addr <= prog_addr + 1;
					end else begin
						//$monitor("{LOOP END %d jmp->%d}", register, current_stack_ptr);
						prog_addr <= prog_stack[stack_index - 1];
					end
				end
				`ZERO: begin
					$monitor("Program ended");
					//$finish;
				end
				default: begin
				end
			endcase
		end
	*/
	end else begin
		// CPU halted
	end
end

endmodule
