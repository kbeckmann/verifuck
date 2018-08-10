`default_nettype none

`include "baudgen.vh"

module verifuck(input clk, input cpu_clk, output [3:0] leds, output uart_tx_pin, input uart_rx_pin);
	parameter UART_TX_BAUD = `B115200;
	parameter DATA_ADDR_WIDTH = 16;
	parameter DATA_VALUE_WIDTH = 32;
	parameter DATA_COUNT = 512;
	parameter PROG_ADDR_WIDTH = 16;
	parameter PROG_VALUE_WIDTH = 8;
	parameter PROG_COUNT = 1024*3;

	reg reset;
	wire resetn = !reset;

	wire [PROG_ADDR_WIDTH-1:0] prog_addr;
	wire prog_ren;
	wire [DATA_ADDR_WIDTH-1:0] data_addr;
	wire data_wen;
	wire data_ren;
	wire [DATA_VALUE_WIDTH-1:0] data_wval;
	wire [DATA_VALUE_WIDTH-1:0] data_rval;
	wire [PROG_VALUE_WIDTH-1:0] prog_rval;

	wire [7:0] stdout;
	wire stdout_en;
	reg [2:0] stdout_en_r = 0;

	// uart_tx
	wire uart_tx_ready;
	reg uart_tx_start;
	reg uart_tx_start_r;

	assign leds = {uart_tx_start, stdout[0], stdout_en, cpu_clk};

	initial begin
		reset = 1;
		uart_tx_start = 0;
	end

	// Halt the CPU while UART is busy
	wire cpu_en = uart_tx_ready;

	always @(posedge clk) begin
		reset <= 0;

		// uart_tx_start lags behind several clock cycles
		stdout_en_r <= {stdout_en_r[1:0], stdout_en};
		uart_tx_start_r <= uart_tx_start;

		// Basically posedge stdout_en
		if (!stdout_en_r && stdout_en) begin
			uart_tx_start <= 1;
		end else if (uart_tx_start_r) begin
			uart_tx_start <= 0;
		end
	end

	proc #(
		.DATA_ADDR_WIDTH(DATA_ADDR_WIDTH),
		.DATA_VALUE_WIDTH(DATA_VALUE_WIDTH),
		.PROG_ADDR_WIDTH(PROG_ADDR_WIDTH),
		.PROG_VALUE_WIDTH(PROG_VALUE_WIDTH)
	)
	myproc (
		.prog_addr(prog_addr),
		.prog_ren(prog_ren),
		.data_addr(data_addr),
		.data_wen(data_wen),
		.data_ren(data_ren),
		.stdout(stdout),
		.stdout_en(stdout_en),
		.data_wval(data_wval),
		.data_rval(data_rval),
		.prog_rval(prog_rval),
		.en(cpu_en),
		.clk(cpu_clk),
		.reset(reset)
	);

	blockram #(
		.DATA_WIDTH(DATA_VALUE_WIDTH),
		.ADDR_WIDTH(DATA_ADDR_WIDTH),
		.NUM_WORDS(DATA_COUNT),
		.HEXFILE("test_ram.mem")
	)
	data_ram (
		.clk(cpu_clk),
		.wen(data_wen),
		.ren(data_ren),
		.waddr(data_addr),
		.raddr(data_addr),
		.wdata(data_wval),
		.rdata(data_rval)
	);

	rom #(
		.DATA_WIDTH(PROG_VALUE_WIDTH),
		.ADDR_WIDTH(PROG_ADDR_WIDTH),
		.NUM_WORDS(PROG_COUNT)
	)
	program_rom (
		.clk(cpu_clk),
		.ren(prog_ren),
		.raddr(prog_addr),
		.rdata(prog_rval)
	);

	uart_tx #(.BAUD(UART_TX_BAUD))
		TX0 (
			.clk(clk),
			.rstn(resetn),
			.data(stdout),
			.start(uart_tx_start),
			.ready(uart_tx_ready),
			.tx(uart_tx_pin)
		);

endmodule


`ifdef FORMAL
module verifuck_formal(
		input clk,
		input reset,
		// output uart_tx_pin,
		input uart_rx_pin,

		input wire [PROG_VALUE_WIDTH-1:0] prog_rval,
	);

	parameter UART_TX_BAUD = `B115200;
	parameter DATA_ADDR_WIDTH = 16;
	parameter DATA_VALUE_WIDTH = 32;
	parameter DATA_COUNT = 512;
	parameter PROG_ADDR_WIDTH = 16;
	parameter PROG_VALUE_WIDTH = 8;
	parameter PROG_COUNT = 1024*3;

	wire resetn = !reset;

	wire [PROG_ADDR_WIDTH-1:0] prog_addr;
	wire prog_ren;
	wire [DATA_ADDR_WIDTH-1:0] data_addr;
	wire data_wen;
	wire data_ren;
	wire [DATA_VALUE_WIDTH-1:0] data_wval;
	wire [DATA_VALUE_WIDTH-1:0] data_rval;

	wire [7:0] stdout;
	wire stdout_en;
	reg [2:0] stdout_en_r = 0;

	// uart_tx
	wire uart_tx_ready;
	reg uart_tx_start;
	reg uart_tx_start_r;

	initial begin
		restrict (reset); // Force initial high
		uart_tx_start = 0;
	end

	// (don't) Halt the CPU while UART is busy
	reg cpu_en = 1;
	// wire cpu_en = uart_tx_ready;

	reg f_last_clk = 1;
	always @($global_clock) begin
		restrict(clk == !f_last_clk);
		f_last_clk <= clk;
	end

	proc #(
		.DATA_ADDR_WIDTH(DATA_ADDR_WIDTH),
		.DATA_VALUE_WIDTH(DATA_VALUE_WIDTH),
		.PROG_ADDR_WIDTH(PROG_ADDR_WIDTH),
		.PROG_VALUE_WIDTH(PROG_VALUE_WIDTH)
	)
	myproc (
		.prog_addr(prog_addr),
		.prog_ren(prog_ren),
		.data_addr(data_addr),
		.data_wen(data_wen),
		.data_ren(data_ren),
		.stdout(stdout),
		.stdout_en(stdout_en),
		.data_wval(data_wval),
		.data_rval(data_rval),
		.prog_rval(prog_rval),
		.en(cpu_en),
		.clk(clk),
		.reset(reset)
	);

	blockram #(
		.DATA_WIDTH(DATA_VALUE_WIDTH),
		.ADDR_WIDTH(DATA_ADDR_WIDTH),
		.NUM_WORDS(DATA_COUNT),
		.HEXFILE("test_ram.mem")
	)
	data_ram (
		.clk(clk),
		.wen(data_wen),
		.ren(data_ren),
		.waddr(data_addr),
		.raddr(data_addr),
		.wdata(data_wval),
		.rdata(data_rval)
	);
/*
	uart_tx #(.BAUD(UART_TX_BAUD))
		TX0 (
			.clk(clk),
			.rstn(resetn),
			.data(stdout),
			.start(uart_tx_start),
			.ready(uart_tx_ready),
			.tx(uart_tx_pin)
		);
*/

always @(posedge clk) begin
	// TODO
end

endmodule
`endif
