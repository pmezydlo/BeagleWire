module top (input         clk,
            output [3:0]  led,
            inout  [15:0] gpmc_ad,
            input         gpmc_advn,
            input         gpmc_csn1,
            input         gpmc_wein,
            input         gpmc_oen,
            input         gpmc_clk,
            input  [1:0]  btn,

            output        sck,
            output        mosi,
            input         miso,
            output        spi_cs,
            output [7:0]  spi_debug);

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
        mem[3][7:0] <= spi_data_out;
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

/* here should be spi controller
 * memory map
 * offset | name               |
 *--------+--------------------+
 *    0   | setup register     |
 *    2   | status register     |
 *    4   | tranceive register |
 *    6   | receive register   |
 *    8   | cs line register   |
 *
 *
 * setup register
 *   bit  |
 *--------+--------------------+
 *    0   |  reset controller  |
 *    1   |  send data         |
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

wire reset;
wire start;

wire busy;
wire new_data;

wire [7:0] spi_ata_in;
reg [7:0] spi_data_out;

assign reset = mem[0][0];
assign start = mem[0][1];
assign spi_data_in = mem[2][7:0];
assign led[0] = spi_cs;

assign spi_cs = mem[4][0];

spi spi_master (
    .clk(clk),
    .rst(reset),
    .miso(miso),
    .mosi(mosi),
    .sck(sck),
    .start(start),
    .data_in(spi_data_in),
    .data_out(spi_data_out),
    .busy(busy),
    .new_data(new_data),
);

assign spi_debug[0] = reset;
assign spi_debug[1] = start;
assign spi_debug[2] = busy;
assign spi_debug[3] = new_data;

endmodule
