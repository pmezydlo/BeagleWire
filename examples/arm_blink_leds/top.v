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

gpmc_sync #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH))
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
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH))
dual_port_ram (
    .rst(1'b0),
    .clk(clk),
    .cs_0(cs),
    .we_0(we),
    .oe_0(oe),
    .addr_0(address),
    .data_in_0(data_out),
    .data_out_0(data_in),

    .cs_1(led_cs),
    .we_1(1'b1),
    .oe_1(1'b0),
    .addr_1(4'b0000),
    .data_in_1(),
    .data_out_1(led_data),
);

reg [DATA_WIDTH-1:0] led_data;
reg led_cs;
reg [10:0] counter;

always @ (posedge clk)
begin
    if (counter[10] == 1'b1)
        led_cs <= 1'b0;
    else
        led_cs <= 1'b1;

    counter <= counter + 1;
end

assign pmod1[0] = led_cs;
assign led = led_data[3:0];

endmodule
