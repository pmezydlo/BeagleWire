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

wire oe;
wire we;
wire cs;
wire [ADDR_WIDTH-1:0]  address;
wire [DATA_WIDTH-1:0]  data_out;
wire[DATA_WIDTH-1:0]  data_in;

assign pmod1[0] = cs;
assign pmod1[1] = we;
assign pmod1[2] = oe;
assign pmod2 = data_in[7:0];
assign pmod3 = data_out[7:0];
assign pmod4[ADDR_WIDTH-1:0] = address[ADDR_WIDTH-1:0];

gpmc_sync #(
    .DATA_WIDTH(16),
    .ADDR_WIDTH(4)) 
gpmc_controller (
    .clk(clk), 
    
    .gpmc_ad(gpmc_ad), 
    .gpmc_advn(gpmc_advn), 
    .gpmc_csn1(gpmc_csn1), 
    .gpmc_wein(gpmc_wein), 
    .gpmc_oen(gpmc_oen), 
    .gpmc_clk(gpmc_clk), 

    .oe(oe),
    .we(we),
    .cs(cs),
    .address(address),
    .data_out(data_out),
    .data_in(data_in),
);
        
dp_sync_ram #(
    .DATA_WIDTH(16),
    .ADDR_WIDTH(4))
dual_port_ram (
    .clk(clk),

    .cs_0(cs),
    .we_0(we),
    .oe_0(oe),
    .addr_0(address),
    .data_in_0(data_out),
    .data_out_0(data_in),

    .cs_1(),
    .we_1(),
    .oe_1(),
    .addr_1(),
    .data_in_1(),
    .data_out_1(), 
);

endmodule 
