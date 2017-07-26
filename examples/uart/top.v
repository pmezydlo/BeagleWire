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
  //      mem[0][2] <= uart_tx_new_data;
  //      mem[0][3] <= uart_tx_busy;
        mem[0][3] <= fifo_empty;
        mem[0][4] <= fifo_full;
        mem[2]    <= fifo_data_out;
        mem[3][3:0] <= fifo_counter;
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

wire fifo_rst;
wire [15:0] fifo_data_in;
reg  [15:0] fifo_data_out;
wire fifo_wr_en;
wire fifo_rd_en;
wire fifo_empty;
wire fifo_full;
wire [3:0] fifo_counter;

assign fifo_rst     = mem[0][0];
assign fifo_wr_en   = mem[0][1];
assign fifo_rd_en   = mem[0][2];
assign fifo_data_in = mem[1];

fifo uart_fifo (
    .clk(clk),
    .rst(fifo_rst),
    .in(fifo_data_in),
    .out(fifo_data_out),
    .wr_en_in(fifo_wr_en),
    .rd_en_in(fifo_rd_en),
    .empty(fifo_empty),
    .full(fifo_full),
    .counter(fifo_counter),
);
/*
initial begin
    mem[0][0] <= 1'b1;
end

wire        uart_tx_rst;
wire [15:0] uart_tx_data;
wire        uart_tx_en;
reg         uart_tx_new_data;
wire [4:0]  uart_tx_bits_per_word;
wire        uart_tx_busy;
wire [15:0] uart_tx_clk_div;

assign uart_tx_clk_div       = mem[2];
assign uart_tx_rst           = mem[0][0];
assign uart_tx_en            = mem[0][1];
assign uart_tx_bits_per_word = mem[0][8:4];
assign uart_tx_data          = mem[1];

uart_tx uart1_tx (
    .rst(uart_tx_rst),
    .data_in(16'h0050),
    .wr_en(uart_tx_en),
    .clk(clk),
    .tx(pmod1[0]),
    .new_data(uart_tx_new_data),
    .busy(uart_tx_busy),
    .bits_per_word(5'b01000),
    .clk_div(uart_tx_clk_div),
);

assign pmod1[1] = uart_tx_new_data;
assign pmod1[2] = uart_tx_busy;
*/
endmodule
