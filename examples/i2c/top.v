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

        mem[1][1] <= tx_fifo_empty;
        mem[1][2] <= tx_fifo_full;
        mem[1][8:3] <= tx_fifo_counter;

        mem[2][1] <= rx_fifo_empty;
        mem[2][2] <= rx_fifo_full;
        mem[2][8:3] <= rx_fifo_counter;

        mem[3][15:8] <= fifo_data_read;

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
reg [7:0]  data_write;
wire       tx_fifo_empty;
wire       tx_fifo_full;
wire       rx_fifo_empty;
wire       rx_fifo_full;
wire [5:0] tx_fifo_counter;
wire [5:0] rx_fifo_counter;
wire       fifo_tx_new_data;
wire       fifo_rx_new_data;
reg [7:0]  fifo_data_read;
wire       busy;
wire       ack_err;
wire       en;
wire       rd_en;
wire       wr_en;
wire       acK_err;

assign wr_en = (!mem[0][2] && !tx_fifo_empty) ? 1'b1: 1'b0;
assign rd_en = (mem[0][2] && !rx_fifo_full && rx_fifo_counter <= mem[0][10:5]) ? 1'b1 : 1'b0;
assign en    = (mem[0][1] && (rd_en || wr_en)) ? 1'b1 : 1'b0;

i2c_master i2c1 (
    .clk(clk),
    .rst(mem[0][0]),

    .scl(scl),
    .sda(sda),
    
    .enable(en),
    .addr(7'h50),
    .rw(mem[0][2]),
    .busy(busy),
    .ack_error(ack_err),
    .data_rd(data_read),
    .data_wr(data_write),
    .fifo_tx(fifo_tx_new_data),
    .fifo_rx(fifo_rx_new_data),
);

fifo #(5, 8)
tx_fifo (
    .clk(clk),
    .rst(mem[0][0]),
    .in(mem[3][7:0]),
    .out(data_write),
    .wr_en_in(mem[1][0]),
    .rd_en_in(fifo_tx_new_data),
    .empty(tx_fifo_empty),
    .full(tx_fifo_full),
    .counter(tx_fifo_counter),
);

fifo #(5, 8)
rx_fifo (
    .clk(clk),
    .rst(mem[0][0]),
    .in(data_read),
    .out(fifo_data_read),
    .wr_en_in(fifo_rx_new_data),
    .rd_en_in(mem[2][0]),
    .empty(rx_fifo_empty),
    .full(rx_fifo_full),
    .counter(rx_fifo_counter),
);

assign led[0] = mem[0][0];
assign led[1] = mem[0][1];
assign led[2] = wr_en;
assign led[3] = rd_en;

assign pmod2[0] = fifo_tx_new_data;
assign pmod2[1] = fifo_rx_new_data;

/*
Memory map:

 offset    | register name                                                             |
-----------+---------------------------------------------------------------------------+
    0x00   | Setup register                                                            |
-----------+---------------------------------------------------------------------------+
    0x02   | FIFO TX setup register                                                    |
-----------+---------------------------------------------------------------------------+
    0x04   | FIFO RX setup register                                                    |
-----------+---------------------------------------------------------------------------+
    0x06   | FIFO TX and RX data register                                              |
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
   10-5 |    1    |  R/W | Read/Write data counter                 |
--------+---------+------+-----------------------------------------+


FIFO TX setup register (0x02)
   bit  | default |      | destination          |
--------+---------+------+----------------------+
    0   |    0    |  R/W | Write data           |
--------+---------+------+----------------------+
    1   |    0    |  RO  | FIFO empty           |
--------+---------+------+----------------------+
    2   |    0    |  RO  | FIFO full            |
--------+---------+------+----------------------+
   8-3  |    0    |  R/W | FIFO data counter    |
--------+---------+------+----------------------+

FIFO RX setup register (0x04)
   bit  | default |      | destination          |
--------+---------+------+----------------------+
    0   |    0    |  R/W | Read data            |
--------+---------+------+----------------------+
    1   |    0    |  RO  | FIFO empty           |
--------+---------+------+----------------------+
    2   |    0    |  RO  | FIFO full            |
--------+---------+------+----------------------+
   8-3  |    0    |  R/W | FIFO data counter    |
--------+---------+------+----------------------+

FIFO TX and RX data register (0x06)
   bit  | default |      | destination          |
--------+---------+------+----------------------+
   7-0  |    0    |  R/W | Data to send         |
--------+---------+------+----------------------+
  15-8  |    0    |  RO  | Read data            |
--------+---------+------+----------------------+

*/

endmodule
