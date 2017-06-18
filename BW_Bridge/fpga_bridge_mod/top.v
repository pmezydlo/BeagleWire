module top (input         clk, 
            output [3:0]  led,
            inout  [15:0] gpmc_ad,
            input         gpmc_advn,
            input         gpmc_csn1,
            input         gpmc_wein,
            input         gpmc_oen,
            input         gpmc_clk,
            input  [1:0]  btn,
            output [7:0]  pmod1,
            output [7:0]  pmod2,
            output [7:0]  pmod3,
            output [7:0]  pmod4);

parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;

reg [ADDR_WIDTH-1:0] addr;
reg [DATA_WIDTH-1:0] mem [ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] data_out;
wire [DATA_WIDTH-1:0] data_in;

initial begin
    addr <= 3'b0;
    data_out <= 16'b0;
end

SB_IO # (
    .PIN_TYPE(6'b1010_01),
    .PULLUP(1'b 0)
) gpmc_ad_io [15:0] (
    .PACKAGE_PIN(gpmc_ad),
    .OUTPUT_ENABLE(!gpmc_csn1 && gpmc_advn && !gpmc_oen && gpmc_wein),
    .D_OUT_0(data_out),
    .D_IN_0(data_in)
);

always @ (negedge gpmc_clk)
begin : GPMC_LATCH_ADDRESS   
    if (!gpmc_csn1 && !gpmc_advn && gpmc_wein && gpmc_oen)
        addr <= data_in[ADDR_WIDTH-1:0];
end

always @ (negedge gpmc_clk)
begin : GPMC_WRITE_DATA   
    if (!gpmc_csn1 && gpmc_advn && !gpmc_wein && gpmc_oen)
        mem[addr] <= data_in;
end

always @ (negedge gpmc_clk)
begin : GPMC_READ_DATA   
    if (!gpmc_csn1 && gpmc_advn && !gpmc_wein && gpmc_oen)
        data_out <= mem[addr];
end

assign led = mem[0][3:0];

endmodule
