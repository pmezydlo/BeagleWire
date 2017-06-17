module top (input         clk, 
            output [3:0]  led,
            inout         gpmc_ad0, 
            input         gpmc_ad1,
            inout         gpmc_ad2, 
            inout         gpmc_ad3, 
            inout         gpmc_ad4, 
            inout         gpmc_ad5, 
            inout         gpmc_ad6,
            inout         gpmc_ad7,
            inout         gpmc_ad8, 
            inout         gpmc_ad0, 
            inout         gpmc_ad9, 
            inout         gpmc_ad10, 
            inout         gpmc_ad11, 
            inout         gpmc_ad12, 
            inout         gpmc_ad13, 
            inout         gpmc_ad14, 
            inout         gpmc_ad15,
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

reg [ADDR_WIDTH:0] addr;
reg [DATA_WIDTH-1:0] mem [ADDR_WIDTH-1:0];
reg [DATA_WIDTH-1:0] data_out;
reg [DATA_WIDTH-1:0] data_in;

reg data_out;
reg data_in;

initial begin
    addr <= 3'b000;
    data_out <= 16'b0000_0000_0000_0000;
end

SB_IO # (
    .PIN_TYPE(6'b1010_01),
    .PULLUP(1'b 0)
) gpmc_ad_io [15:0] (
    .PACKAGE_PIN({gpmc_ad0, gpmc_ad1, gpmc_ad2, gpmc_ad3, gpmc_ad4, gpmc_ad5, gpmc_ad6, gpmc_ad7, gpmc_ad8, gpmc_ad9, gpmc_ad10, gpmc_ad11, gpmc_ad12, gpmc_ad13, gpmc_ad14, gpmc_ad15}),
    .OUTPUT_ENABLE(!gpmc_csn1 && gpmc_advn && !gpmc_oen && gpmc_wein),
    .D_OUT_0(data_out),
    .D_IN_0(data_in)
);

always @ (negedge gpmc_clk)
begin : GPMC_LATCH_ADDRESS   
    if (!gpmc_csn1 && !gpmc_advn && gpmc_wein && gpmc_oen)
        addr <= gpmc_ad[ADDR_WIDTH-1:0];
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
