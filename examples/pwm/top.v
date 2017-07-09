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
            output [7:0]  pmod4,); 

parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH];

reg oe;
reg we;
reg cs;
wire[ADDR_WIDTH-1:0]  addr;
reg [DATA_WIDTH-1:0]  data_out;
wire [DATA_WIDTH-1:0]  data_in;

always @ (posedge clk)
begin
    if (!cs && !we && oe) begin
        mem[addr] <= data_out;
    end
end

always @ (posedge clk)
begin
    if (!cs && we && !oe) begin
        data_in <= mem[addr];
    end else begin
        data_in <= 0;
    end
end

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
    .address(addr),
    .data_out(data_out),
    .data_in(data_in),
);

   /*
    * pwm memory map
    *
    * offset | destination
    *    0   |  setup
    *    2   |  period
    *    6   |  duty cycle
    *    10   |  --
    */

wire en;
wire polarity;
wire [32:0] period;
wire [32:0] duty_cycle;

assign en = mem[0][0];
assign polarity = mem[0][1];
assign period[31:16] = mem[1];
assign period[15:0] = mem[2];
assign duty_cycle[31:16] = mem[3];
assign duty_cycle[15:0] = mem[4];

pwm pwm1 (
    .en(en),
    .period(period),
    .duty_cycle(duty_cycle),
    .polarity(polarity),
    .clk(clk),
    .out(pmod1[0]),
);


endmodule
