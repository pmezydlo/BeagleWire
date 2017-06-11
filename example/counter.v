module top(input CLK_100M, output [3:0] LED);

	reg [27:0] counter = 0;
	always @(posedge CLK_100M) counter <= counter + 1;

	assign LED[0:3] = counter[24:27];
endmodule
