module top (input         CLK_100M, 
            output [3:0]  LED,
            inout  [15:0] GPMC_AD,
            input         GPMC_ADVN,
            input         GPMC_CSN1,
            input         GPMC_WEIN,
            input         GPMC_OEN,
            input         GPMC_CLK,
            input  [1:0]  BTN,
            output [7:0]  PMOD1,
            output [7:0]  PMOD2,
            output [7:0]  PMOD3,
            output [7:0]  PMOD4);

parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;

reg [ADDR_WIDTH:0] addr;
reg [DATA_WIDTH-1:0] mem [ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] data_out;

initial begin
    addr <= 3'b000;
    data_out <= 16'b0000_0000_0000_0000;
end

assign GPMC_AD = (!GPMC_CSN1 && GPMC_ADVN && !GPMC_OEN && GPMC_WEIN) ? data_out : 16'bz;

always @ (negedge CLK_100M)
begin : GPMC_LATCH_ADDRESS   
    if (!GPMC_CSN1 && !GPMC_ADVN && GPMC_WEIN && GPMC_OEN)
        addr <= GPMC_AD[ADDR_WIDTH-1:0];
end

always @ (negedge CLK_100M)
begin : GPMC_WRITE_DATA   
    if (!GPMC_CSN1 && GPMC_ADVN && !GPMC_WEIN && GPMC_OEN)
        mem[addr] <= GPMC_AD[DATA_WIDTH-1:0];
end

always @ (negedge GPMC_CLK)
begin : GPMC_READ_DATA   
    if (!GPMC_CSN1 && GPMC_ADVN && !GPMC_WEIN && GPMC_OEN)
        data_out <= mem[addr];
end

assign LED = mem[0][3:0];

endmodule
