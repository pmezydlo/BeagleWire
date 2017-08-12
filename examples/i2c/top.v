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
            output  [7:0]    pmod2);

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
        mem[1][1] <= tx_fifo_empty;
        mem[1][2] <= tx_fifo_full;
        mem[1][8:3] <= tx_fifo_counter;
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

reg [7:0] data_write;
wire tx_fifo_empty;
wire tx_fifo_full;
wire [5:0] tx_fifo_counter;
wire fifo_tx_new_data;

wire en;
assign en = (mem[0][1] && !tx_fifo_empty) ? 1'b1 : 1'b0;

i2c_master i2c1 (
    .clk(clk),
    .rst(mem[0][0]),

    .scl(scl),
    .sda(sda),
    
    .enable(en),
    .addr(7'h50),
    .rw(1'b0),
    .busy(pmod2[0]),
    .ack_error(pmod2[1]),
    .data_rd(),
    .data_wr(data_write),
    .fifo_tx(fifo_tx_new_data),
    .debug(pmod2[2:7]),
);

fifo #(5, 8)
tx_fifo (
    .clk(clk),
    .rst(mem[0][0]),
    .in(mem[2][7:0]),
    .out(data_write),
    .wr_en_in(mem[1][0]),
    .rd_en_in(fifo_tx_new_data),
    .empty(tx_fifo_empty),
    .full(tx_fifo_full),
    .counter(tx_fifo_counter),
);


assign led[0] = mem[0][0];
assign led[1] = mem[0][1];

endmodule
