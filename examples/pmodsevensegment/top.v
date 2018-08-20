module top(input clk,
	   output [3:0] led,
	   output [7:4] pmod1,);

   reg [27:0] counter = 0;
   always @(posedge clk) counter <= counter + 1;

   assign led[0:3] = counter[24:27];
   assign pmod1[4:7] = counter[24:27];

endmodule
