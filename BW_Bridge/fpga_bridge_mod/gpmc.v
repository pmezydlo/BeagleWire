module gpmc(input           CLK_100M, 
            output  [3:0]   LED,
            input   [15:0]  GPMC_AD,
            input           GPMC_ADVN,
            input           GPMC_BE0N,
            input           GPMC_CSN1,
            input           GPMC_WEIN,
            input           GPMC_OEN,
            input           GPMC_CLK,
            input   [1:0]   BTN);
            
wire reset;
reg [2:0] state;

assign reset = BTN[0];
assign LED[0] = BTN[1];

parameter STATE_IDLE = 3'b000, STATE_ADDR = 3'b001, STATE_NAND_CMD = 3'b010;

always @ (posedge CLK_100M)
begin
    if (reset == 1'b1) begin
        state <= STATE_IDLE;
        LED[3] = 1'b0;
    end else begin
        LED[3] = 1'b1;

    end
end

endmodule
