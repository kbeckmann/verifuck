`include "baudgen.vh"

module verifuck(input clk, output [3:0] leds, output uart_tx_pin, input uart_rx_pin);

	reg reset;
	wire resetn = !reset;

	reg [25:0] counter = 0;
	wire clk_downsampled;
	assign clk_downsampled = counter[22];

	initial begin
		reset = 1;
		uart_tx_start = 0;
	end

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

	// uart_tx
	wire ready;
	reg uart_tx_start;

	reg blinky = 0;
	assign leds = {uart_tx_pin, stdout[0], stdout_en, clk_downsampled};
	reg [3:0] temp;

	always @(posedge clk) begin
		counter <= counter + 1;
		reset <= 0;
		if (ready && stdout_en)
			uart_tx_start <= 1;
		else
			uart_tx_start <= 0;
	end

	proc myproc (
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
		.clk(clk_downsampled),
		.reset(reset)
	);

	blockram data_ram (
		.clk(clk_downsampled),
		.wen(data_wen),
		.ren(data_ren),
		.waddr(data_addr),
		.raddr(data_addr),
		.wdata(data_wval),
		.rdata(data_rval)
	);

	rom program_rom (
		.clk(clk_downsampled),
		.ren(prog_ren),
		.raddr(prog_addr),
		.rdata(prog_rval)
	);

	parameter BAUD = `B115200;
	uart_tx #(.BAUD(BAUD))
		TX0 (
			.clk(clk),
			.rstn(resetn),
			.data(stdout),
			.start(uart_tx_start),
			.ready(ready),
			.tx(uart_tx_pin)
		);

endmodule
