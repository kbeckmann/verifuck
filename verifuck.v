module verifuck(input clk, output [3:0] leds);
wire clk;

reg [25:0] data = 0;
assign leds = data[25:22];
always @(posedge clk) begin
	data <= data + 4;
end

endmodule

