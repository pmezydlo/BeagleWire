module top(input CLK_100M, output [3:0] LED);

	reg [25:0] counter = 0;
	always @(posedge CLK_100M) counter <= counter + 1;

	assign LED[0:3] = counter[22:25];
endmodule
