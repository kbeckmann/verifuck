module verifuck_tb();

reg clk = 0;

wire [3:0] leds;

reg [25:0] verifuck_check = 1;

verifuck C1(
	.clk(clk),
	.leds(leds)
);

always #1 clk = ~clk;

initial begin
	$dumpfile("verifuck_tb.vcd");
	$dumpvars(0, verifuck_tb);

	# 99 $display("Simulation end");
	# 100 $finish;
end

endmodule
