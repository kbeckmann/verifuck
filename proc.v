// set the opcodes. this takes the ascii value of
// these keys so a brainfuck program can go straight
// into memory, at the expense of a few bits.
`define INCDP   ">"
`define DECDP   "<"
`define INCDATA "+"
`define DECDATA "-"
`define OUTONE  "."
`define INONE   ","
`define CONDJMP "["
`define JMPBACK "]"

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

reg [7:0] prog_addr;
reg prog_ren;
reg [7:0] data_addr;
reg data_wen;
reg data_ren;
reg [7:0] data_wval = 0;

`define STATE_RESET			3'b000
`define STATE_FETCHDECODE	3'b001
`define STATE_EXECUTE		3'b010
`define STATE_WRITE			3'b100

reg [2:0] state = `STATE_RESET;

always @(posedge clk) begin
	if (reset) begin
		state <= `STATE_RESET;
		prog_ren <= 0;
		data_wen <= 0;
		data_ren <= 0;
		data_addr <= 0;
		prog_addr <= 0;
	end else begin
		//$monitor("executing: %c", prog_rval);
		case (state)
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
			data_wen <= 0;
			data_ren <= 1;
			prog_addr <= prog_addr + 1;
			end
		`STATE_WRITE: begin
			// Writes data, prepare for read
			prog_ren <= 1;
			data_wen <= 0;
			data_ren <= 1;
			state <= `STATE_FETCHDECODE;
			end
		default: begin
			end
		endcase

		if (state == `STATE_EXECUTE) begin
			if (prog_rval == `INCDATA || prog_rval == `DECDATA) begin
				data_wen <= 1;
				state <= `STATE_WRITE;
			end else begin
				data_wen <= 0;
				state <= `STATE_FETCHDECODE;
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
					//$write("%c", data_rval);
					end
				`INONE: begin
					//data <= myin;
					//data_wval <= data;
					//data_wen <= 1;
					//prog_addr <= prog_addr+1;
					//data_wen <= 0;
					end
				`CONDJMP: begin
					//data_wen <= 0;
					end
				`JMPBACK: begin
					//data_wen <= 0;
					end
				default: begin
					data_addr <= 0;
					prog_addr <= 0;
					end
			endcase //undefined opcodes not supported
		end
	end
end

endmodule
