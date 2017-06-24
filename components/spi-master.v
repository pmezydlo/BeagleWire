module top (//input                        rst,
                  input                        clk,
              
                   // interface signal
                  //input                        din,
                  //output                       ss,
                  //output                       dout,
                  //output                       sclk,
               
                   // host interface
                  //output                       done,
                  //output [DATA_WIDTH-1:0]      rx_data,
                  //input  [DATA_WIDTH-1:0]      tx_data,
                  //input  [3:0]                 clk_div,
                  //input                        enable,
                  output   [7:0]               pmod1);

reg [3:0] clk_div = 4'b1000;

parameter DATA_WIDTH = 8;
parameter IDLE       = 2'b00;
parameter SEND       = 2'b01;
parameter FINISH     = 2'b11;

reg clk_en;
reg [3:0] counter;

always @ (posedge clk)
begin : CLOCK_GEN
    if (counter == clk_div) begin
        clk_en <= !clk_en;
        counter <= 0;
    end
    counter <= counter + 1;
end

assign pmod1[0] = clk;
assign pmod1[1] = clk_en;

endmodule
