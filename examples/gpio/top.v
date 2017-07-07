module top (input         clk,
            output [3:0]  led,
            inout  [15:0] gpmc_ad,
            input         gpmc_advn,
            input         gpmc_csn1,
            input         gpmc_wein,
            input         gpmc_oen,
            input         gpmc_clk,
            input  [1:0]  btn,
            inout [7:0]   pmod1,
            inout [7:0]   pmod2,
            inout [7:0]   pmod3,
            inout [7:0]   pmod4,
);

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
        mem[2][7:0] <= Output[7:0];
        mem[2][15:8] <= Output[15:8];
        mem[3][7:0] <= Output[23:16];
        mem[3][15:8] <= Output[31:24];
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
 * memory map
 * offset | name   16 bit data |
 *--------+--------------------+
 *    0   | direct register    |
 *    2   | direct register    |
 *    4   | output register    |
 *    6   | output register    |
 *    8   | input register     |
 *    10  | input register     |
 */

wire [31:0] dir;
wire [31:0] Input;
wire [31:0] Output;

assign dir[15:0] = mem[0];
assign dir[31:16] = mem[1];
assign Input[15:0] = mem[4];
assign Input[31:16] = mem[5];

gpio_port port1 (
    .io(pmod1),
    .dir(dir[7:0]),
    .Input(Input[7:0]),
    .Output(Output[7:0]),
);

gpio_port port2 (
    .io(pmod2),
    .dir(dir[15:8]),
    .Input(Input[15:8]),
    .Output(Output[15:8]),
);

gpio_port port3 (
    .io(pmod3),
    .dir(dir[23:16]),
    .Input(Input[23:16]),
    .Output(Output[23:16]),
);

gpio_port port4 (
    .io(pmod4),
    .dir(dir[31:24]),
    .Input(Input[31:24]),
    .Output(Output[31:24]),
);

endmodule
