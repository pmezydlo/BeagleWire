module uart_baud_gen(input          en,
                     input          clk,
                     input [15:0]   clk_div,
                     output         clk_out);

reg [15:0] counter;
reg uart_clk_en;

always @(posedge clk)
begin
    if (en == 1'b0) begin
        uart_clk_en <= 0;
        counter <= 0;
    end else begin
       if (counter == clk_div) begin
           clk_out <= 1'b1;
           counter <= 1;
       end else begin
           clk_out <= 1'b0;
           counter <= counter + 1;
       end
    end
end

endmodule
