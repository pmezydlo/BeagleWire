module top (input         clk,
            output [7:0]  pmod1);

wire clkout;
wire lock;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0100),
        .DIVF(7'b0101111),
        .DIVQ(3'b100),
        .FILTER_RANGE(3'b010)
    ) uut (
        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(clkout)
    );

assign pmod1[0] = clk;
assign pmod1[1] = clkout;
assign pmod1[2] = lock;

endmodule
