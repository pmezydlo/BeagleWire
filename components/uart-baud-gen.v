module uart_baud_gen(input          en,
                     input          clk,
                     input [15:0]   clk_div,
                     output         uart_clk_en);

reg [15:0] counter;
reg uart_clk_en;

always @(posedge clk)
begin
    if (en == 1'b0) begin
        uart_clk_en <= 0;
        counter <= 0;
    end else begin
       if (counter == clk_div) begin 
           uart_clk_en <= 1'b1;
           counter <= 1;
       end else begin
           uart_clk_en <= 1'b0;
           counter <= counter + 1;
       end
    end
end

endmodule
