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
        mem[0][2] <= uart_tx_new_data;
        mem[0][3] <= uart_tx_busy;
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

wire        uart_clk_out;
wire [15:0] uart_clk_div;
wire        uart_clk_en;

wire [15:0] uart_tx_data;
wire        uart_tx_en;
reg         uart_tx_new_data;
wire [4:0]  uart_tx_bits_per_word;
wire        uart_tx_busy;

assign uart_clk_en           = mem[0][0];
assign uart_clk_div          = mem[3];

assign uart_tx_en            = mem[0][1];
assign uart_tx_bits_per_word = mem[0][8:4];/*verificate how long are the uart words*/
assign uart_tx_data          = mem[1];

uart_baud_gen uart1_bg (
    .en(uart_clk_en),
    .clk(clk),
    .clk_div(uart_clk_div),
    .clk_out(uart_clk_out),
);

uart_tx uart1_tx (
    .data_in(uart_tx_data),
    .wr_en(uart_tx_en),
    .clk_100m(clk),
    .tx(pmod1[0]),
    .tx_new_data(uart_tx_new_data),
    .tx_busy(uart_tx_busy),
    .clken(uart_clk_out),
    .bits_per_word(uart_tx_bits_per_word),
);

endmodule
