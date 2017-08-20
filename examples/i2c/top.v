module top (input         clk,
            output [3:0]  led,
            inout  [15:0] gpmc_ad,
            input         gpmc_advn,
            input         gpmc_csn1,
            input         gpmc_wein,
            input         gpmc_oen,
            input         gpmc_clk,
            input  [1:0]  btn,

            inout         scl,
            inout         sda,
            output  [7:0] pmod2);

parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];

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
        mem[0][3] <= busy;
        mem[0][4] <= ack_err;
        mem[1][15:8] <= data_read;
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

initial begin
    mem[0][0] <= 1'b1;
end

reg [7:0]  data_read;
wire       busy;
wire       ack_err;

i2c_master i2c1 (
    .clk(clk),
    .rst(mem[0][0]),
    .scl(scl),
    .sda(sda),
    .enable(mem[0][1]),
    .addr(7'h50),
    .rw(mem[0][2]),
    .busy(busy),
    .ack_error(ack_err),
    .data_rd(data_read),
    .data_wr(mem[1][7:0]),
    .debug(pmod2),
);


//assign pmod2[7:2] = debug;
assign led[0] = mem[0][0];
assign led[1] = mem[0][1];
assign led[2] = busy;
assign led[3] = ack_err;
//assign pmod2[0] = clk;
//assign pmod2[1] = mem[0][1];

/*
Memory map:

 offset    | register name                                                             |
-----------+---------------------------------------------------------------------------+
    0x00   | Setup register                                                            |
-----------+---------------------------------------------------------------------------+
    0x02   | TX and RX data register                                                   |
-----------+---------------------------------------------------------------------------+

Setup register (0x00)
   bit  | default |      | destination                             |
--------+---------+------+-----------------------------------------+
    0   |    1    |  R/W | Reset bit                               |
--------+---------+------+-----------------------------------------+
    1   |    0    |  R/W | Enable bit                              |
--------+---------+------+-----------------------------------------+
    2   |    0    |  R/W | Write/Read bit   0 - Write 1 - Read     |
--------+---------+------+-----------------------------------------+
    3   |    0    |  RO  | Busy bit                                |
--------+---------+------+-----------------------------------------+
    4   |    0    |  RO  | Ack error bit                           |
--------+---------+------+-----------------------------------------+

TX and RX data register (0x02)
   bit  | default |      | destination          |
--------+---------+------+----------------------+
   7-0  |    0    |  R/W | Data to send         |
--------+---------+------+----------------------+
  15-8  |    0    |  RO  | Read data            |
--------+---------+------+----------------------+

*/

endmodule
