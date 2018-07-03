module bf_tb;

	reg clk;
	reg [25:0] counter = 0;
	always #10 clk = !clk;
	wire cpu_clk;
	assign cpu_clk = counter[7];

	wire uart_tx_pin;

	initial begin
		$dumpvars;
		clk = 1;

		#100000 $write("\n");
		#1 $finish;
	end

	always @(posedge clk) begin
		counter <= counter + 1;
	end

	// Pipe stdout to the real stdout
	always @(posedge myfuck.stdout_en) begin
		if (myfuck.stdout_en)
			$write("%c", myfuck.stdout);
	end

	verifuck #(
		.UART_TX_BAUD(4) // super fast baudrate to see the signals when simiulating...
	)
	myfuck (
		.clk(clk),
		.cpu_clk(cpu_clk),
		.uart_tx_pin(uart_tx_pin)
	);

endmodule
