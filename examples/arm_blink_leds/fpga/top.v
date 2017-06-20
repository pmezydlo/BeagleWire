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

wire cs;
wire oe;
wire we;
wire [3:0] addr;
wire [15:0] data;
wire busy;
reg led;

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
    .data(data),
    .oe(oe),
    .we(we),
    .addr(addr),
    .busy(busy),
    .cs(cs),
);
        
assign addr = 4'b0000;
assign cs = 1'b0;

always @ (posedge btn[0])
begin
    if (!busy)
        oe <= !oe;
    else
        oe <= 1'b1;
end

assign led = data[3:0];

endmodule 
