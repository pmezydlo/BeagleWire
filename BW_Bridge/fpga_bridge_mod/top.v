module top (input         CLK_100M, 
            output [3:0]  LED,
            input  [15:0] GPMC_AD,
            input         GPMC_ADVN,
            input         GPMC_CSN1,
            input         GPMC_WEIN,
            input         GPMC_OEN,
            input         GPMC_CLK,
            input  [1:0]  BTN,
            output [7:0]  PMOD1);


localparam MAX_ADDR_WIDTH = 3;


reg [15:0] address;
reg [MAX_ADDR_WIDTH:0] mem [15:0];
reg [MAX_ADDR_WIDTH:0] offset;
wire reset;

assign reset = BTN[1];

always @ (negedge GPMC_CLK or negedge reset) begin
    if (reset == 1'b0) begin
        //mem <= 0;
        address <= 0;
        offset <= 0;
    end else begin
        if (GPMC_CSN1 == 1'b0) begin
            if (GPMC_ADVN == 1'b0)
                address <= GPMC_AD;
            if (GPMC_WEIN == 1'b0) begin
                mem[address[MAX_ADDR_WIDTH:0] + offset] <= GPMC_AD;
                offset <= offset + 1;
            end
            if (GPMC_OEN == 1'b0) begin
                GPMC_AD <= mem[address[MAX_ADDR_WIDTH:0] + offset];
                offset <= offset + 1;
            end
        end
    end
end
        
endmodule
