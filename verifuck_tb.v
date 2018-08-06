`timescale 1 ns / 1 ps
`default_nettype none

module verifuck_tb;

	reg clk;
	reg [25:0] counter = 0;
	always #10 clk = !clk;
	wire cpu_clk;
	// assign cpu_clk = counter[4];
	assign cpu_clk = clk;

	wire uart_tx_pin;

	initial begin
		$dumpvars;
		clk = 1;

		// #5000000 $write("\n");
		#10000000 $write("\n");
`ifdef FORMAL
`else
		#1 $finish;
`endif
	end

	always @(posedge clk) begin
		counter <= counter + 1;
	end

`ifdef FORMAL
`else
	// Pipe stdout to the real stdout
	always @(posedge myfuck.stdout_en) begin
		if (myfuck.stdout_en)
			$write("%c", myfuck.stdout);
	end
`endif

	verifuck #(
		.UART_TX_BAUD(1) // super fast baudrate to see the signals when simiulating...
	)
	myfuck (
		.clk(clk),
		.cpu_clk(cpu_clk),
		.uart_tx_pin(uart_tx_pin)
	);


`ifdef FORMAL
	// TODO
`endif

endmodule
