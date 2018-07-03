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
	clk,		// clock
	reset		// reset, active low
);

output [7:0] prog_addr;
output       prog_ren;
output [7:0] data_addr;
output 	     data_wen;
output       data_ren;
output [7:0] data_wval;
output reg [7:0] stdout = 0;
output reg stdout_en = 0;

input [7:0] data_rval;
input [7:0] prog_rval;
input       clk;
input       reset;

wire [7:0] register = data_rval;

reg [7:0] prog_addr = 0;
reg prog_ren = 0;
reg [7:0] data_addr = 0;
reg data_wen = 0;
reg data_ren = 0;
reg [7:0] data_wval = 0;

reg [7:0] prog_stack [0:7]; // 8 depth stack
reg [7:0] stack_index = 0;

// Used for debugging, they are free when synthesized
wire [7:0] prog_stack_0 = prog_stack[0];
wire [7:0] prog_stack_1 = prog_stack[1];
wire [7:0] prog_stack_2 = prog_stack[2];
wire [7:0] current_stack_ptr = prog_stack[stack_index];

initial begin
	prog_stack[0] = 0;
	prog_stack[1] = 0;
	prog_stack[2] = 0;
	prog_stack[3] = 0;
	prog_stack[4] = 0;
	prog_stack[5] = 0;
	prog_stack[6] = 0;
	prog_stack[7] = 0;
end

`define STATE_STOP			4'b0000
`define STATE_RESET			4'b0001
`define STATE_FETCHDECODE	4'b0010
`define STATE_EXECUTE		4'b0100
`define STATE_PREPARE_FETCH	4'b1000

reg [3:0] state = `STATE_RESET;

always @(posedge clk) begin
	if (reset) begin
		state <= `STATE_RESET;
		prog_ren <= 0;
		data_wen <= 0;
		data_ren <= 0;
		data_addr <= 0;
		prog_addr <= 0;
	end else begin
		//$monitor("state=%d data_addr=%d data_rval=%d prog_addr=%d prog_rval=%d %c",
		//	state, data_addr, data_rval, prog_addr, prog_rval, prog_rval);

		case (state)
		`STATE_STOP: begin
			prog_ren <= 0;
			data_wen <= 0;
			data_ren <= 0;
			end
		`STATE_RESET: begin
			prog_ren <= 1;
			data_wen <= 0;
			data_ren <= 1;
			state <= `STATE_FETCHDECODE;
			end
		`STATE_FETCHDECODE: begin
			// Reads program and data, will be available in the next state
			prog_ren <= 0;
			data_wen <= 0;
			data_ren <= 0;
			stdout_en <= 0;
			state <= `STATE_EXECUTE;
			end
		`STATE_EXECUTE: begin
			// Program and data are ready to be executed
			prog_ren <= 1;
			data_ren <= 1;
			if (prog_rval != `JMPBACK)
				prog_addr <= prog_addr + 1;
			end
		`STATE_PREPARE_FETCH: begin
			// Buffer state for read and write.
			prog_ren <= 1;
			data_wen <= 0;
			data_ren <= 1;
			state <= `STATE_FETCHDECODE;
			end
		default: begin
			end
		endcase

		if (state == `STATE_EXECUTE) begin
			if (prog_rval != `ZERO) begin
				state <= `STATE_PREPARE_FETCH;
			end else begin
				// Get stuck in STOP state forever
				state <= `STATE_STOP;
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
					data_addr <= 0;
					prog_addr <= 0;
				end
			endcase
		end
	end
end

endmodule
