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
);

parameter ADDR_WIDTH = 5;
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
        mem[2][5]    <= tx_busy;
        mem[0][3]    <= fifo_empty;
        mem[0][4]    <= fifo_full;
        mem[0][10:5] <= fifo_counter;
        data_in      <= mem[addr];
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
    mem[2][0] <= 1'b1;
end

wire        transfer_en;
reg  [15:0] fifo_data_out;
wire        fifo_empty;
wire        fifo_full;
wire [5:0]  fifo_counter;
wire        tx_busy;

assign transfer_en = (mem[2][1] && !tx_busy && !fifo_empty) ? 1'b1 : 1'b0;

fifo uart_fifo (
    .clk(clk),
    .rst(mem[0][0]),
    .in(mem[1]),
    .out(fifo_data_out),
    .wr_en_in(mem[0][1]),
    .rd_en_in(transfer_en),
    .empty(fifo_empty),
    .full(fifo_full),
    .counter(fifo_counter),
);

uart_tx uart1_tx (
    .rst(mem[2][0]),
    .data_in(fifo_data_out),
    .wr_en(transfer_en),
    .clk(clk),
    .tx(pmod1[0]),
    .busy(tx_busy),
    .bits_per_word(5'b00111),//mem[2][11:6]),
    .clk_div(mem[3]),
    .parity_en(mem[2][2]),
    .parity_evan_odd(mem[2][3]),
    .two_stop_bit(mem[2][4]),
);

assign pmod1[1] = tx_busy;

assign led[0] = fifo_empty;
assign led[1] = fifo_full;
assign led[2] = tx_busy;

endmodule
