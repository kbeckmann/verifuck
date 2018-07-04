module top(input clk, output [3:0] leds, output uart_tx_pin, input uart_rx_pin);

	reg [25:0] counter = 0;
	wire cpu_clk;

	// Use this to slow down the CPU
	// assign cpu_clk = counter[14];
	// assign cpu_clk = counter[4];
	assign cpu_clk = clk;

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	verifuck myfuck (
		.clk(clk),
		.cpu_clk(cpu_clk),
		.leds(leds),
		.uart_tx_pin(uart_tx_pin),
		.uart_rx_pin(uart_rx_pin)
	);

endmodule
