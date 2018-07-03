`include "baudgen.vh"

module verifuck(input clk, input cpu_clk, output [3:0] leds, output uart_tx_pin, input uart_rx_pin);
	parameter UART_TX_BAUD = `B115200;

	reg reset;
	wire resetn = !reset;

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
	assign leds = {uart_tx_pin, stdout[0], stdout_en, cpu_clk};
	reg [3:0] temp;

	reg stdout_en_ongoing = 0;

	always @(posedge clk) begin
		reset <= 0;
		if (stdout_en) begin
			if (!stdout_en_ongoing) begin
				stdout_en_ongoing <= 1;
				uart_tx_start <= 1;
			end else begin
				if (ready) begin
					uart_tx_start <= 0;
				end
			end
		end else begin
			stdout_en_ongoing <= 0;
		end
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
		.clk(cpu_clk),
		.reset(reset)
	);

	blockram data_ram (
		.clk(cpu_clk),
		.wen(data_wen),
		.ren(data_ren),
		.waddr(data_addr),
		.raddr(data_addr),
		.wdata(data_wval),
		.rdata(data_rval)
	);

	rom program_rom (
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
			.ready(ready),
			.tx(uart_tx_pin)
		);

endmodule
