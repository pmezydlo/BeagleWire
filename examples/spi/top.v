module top (input         clk,
            output [3:0]  led,
            inout  [15:0] gpmc_ad,
            input         gpmc_advn,
            input         gpmc_csn1,
            input         gpmc_wein,
            input         gpmc_oen,
            input         gpmc_clk,
            input  [1:0]  btn,

            output        spi_sck,
            output        spi_mosi,
            input         spi_miso,
            output        spi_cs);

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
        mem[1][0] <= busy;
        mem[1][1] <= new_data;
        mem[5] <= spi_data_out[15:0];
        mem[4] <= spi_data_out[31:16];
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

wire clk_20m;
wire lock;

    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0100),
        .DIVF(7'b0011111),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b010)
    ) uut (
        .LOCK(lock),
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(clk),
        .PLLOUTCORE(clk_20m)
    );

/* here should be spi controller
 * memory map
 * offset | name               |
 *--------+--------------------+
 *    0   | setup register     |
 *    2   | status register    |
 *    4   | tranceive register |
 *    8   | receive register   |
 *
 * setup register
 *   bit  |
 *--------+--------------------+
 *    0   |  reset controller  |
 *    1   |  send data         |
 *    2   |  cpol bit          |
 *    3   |  cpha bit          |
 *    4   |  cs   bit          |
 *   9-5  |  bits per word     |
 *  15-10 |  clock div         |
 *
 * status register
 *   bit  |
 *--------+-----------------------+
 *    0   |  busy                 |
 *    1   |  new data for receive |
 *
 * cs line register
 *  bit   |
 *--------+-----------------------+
 *  7-0   |    each bit is one cs |
 *        |    line               |
 */

localparam MAX_DATA_WIDTH = 32;

// set rest to 1
initial begin
    mem[0][0] <= 1'b1;
end

wire reset;
wire start;
wire cpol;
wire cpha;
wire [4:0] bits_per_word;
wire [5:0] div;

wire busy;
wire new_data;

wire [MAX_DATA_WIDTH-1:0] spi_data_in;
reg  [MAX_DATA_WIDTH-1:0] spi_data_out;

assign spi_data_in[15:0]  = mem[3];
assign spi_data_in[31:16] = mem[2];

assign reset         = mem[0][0];
assign start         = mem[0][1];
assign cpol          = mem[0][2];
assign cpha          = mem[0][3];
assign spi_cs        = mem[0][4];
assign bits_per_word = mem[0][9:5];
assign div           = mem[0][15:10];

spi #(
    .MAX_DATA_WIDTH(MAX_DATA_WIDTH))
spi_master (
    .clk(clk_20m),

    .miso(spi_miso),
    .mosi(spi_mosi),
    .sck(spi_sck),

    .start(start),
    .rst(reset),
    .cpol(cpol),
    .cpha(cpha),
    .bits_per_word(bits_per_word),
    .div(div),

    .data_in(spi_data_in),
    .data_out(spi_data_out),

    .busy(busy),
    .new_data(new_data)
);

assign led[0] = busy;

endmodule
