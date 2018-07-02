module bf_tb;

	reg reset;
	reg clk;

	integer i;
	initial begin
		$dumpvars;

		reset = 1;
		clk = 1;
/*
		for (i = 0; i < program_rom.NUM_WORDS; i += 1) begin
			program_rom.mem[i] <= 0;
		end

		for (i = 0; i < data_ram.NUM_WORDS; i += 1) begin
			data_ram.mem[i] <= 0;
		end

		#10 $readmemh("test_prog.mem", program_rom.mem);
		#10 $readmemh("test_ram.mem", data_ram.mem);
*/
		#30 reset = 0;
		#1000 $finish;
	end

	always #10 clk = !clk;

	wire [7:0] prog_addr;
	wire prog_ren;
	wire [7:0] data_addr;
	wire data_wen;
	wire data_ren;
	wire [7:0] data_wval;
	wire [7:0] data_rval;
	wire [7:0] prog_rval;
	wire [7:0] stdout;
	wire stdout_en;

	wire [7:0] data_temp0 = data_ram.mem[0];
	wire [7:0] data_temp1 = data_ram.mem[1];
	wire [7:0] data_temp2 = data_ram.mem[2];
	wire [7:0] data_temp3 = data_ram.mem[3];

	wire [7:0] prog_temp0 = program_rom.mem[0];
	wire [7:0] prog_temp1 = program_rom.mem[1];
	wire [7:0] prog_temp2 = program_rom.mem[2];
	wire [7:0] prog_temp3 = program_rom.mem[3];

	// "UART tx"
	always @(posedge clk) begin
		if (stdout_en)
			$write("%c", stdout);
	end

	proc myproc (
		.prog_addr(prog_addr),
		.prog_ren(prog_ren),
		.data_addr(data_addr),
		.data_wen(data_wen),
		.data_ren(data_ren),
		.data_wval(data_wval),
		.stdout(stdout),
		.stdout_en(stdout_en),
		.data_rval(data_rval),
		.prog_rval(prog_rval),
		.clk(clk),
		.reset(reset)
	);

	blockram data_ram (
		.clk(clk),
		.wen(data_wen),
		.ren(data_ren),
		.waddr(data_addr),
		.raddr(data_addr),
		.wdata(data_wval),
		.rdata(data_rval)
	);

	rom program_rom (
		.clk(clk),
		.ren(prog_ren),
		.raddr(prog_addr),
		.rdata(prog_rval)
	);

endmodule
