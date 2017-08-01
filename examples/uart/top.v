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
            input  [7:0]  pmod2,
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
        mem[0][2]    <= tx_busy;
        mem[2][1]    <= tx_fifo_empty;
        mem[2][2]    <= tx_fifo_full;
        mem[2][8:3]  <= tx_fifo_counter;
        mem[6][1]    <= rx_fifo_empty;
        mem[6][2]    <= rx_fifo_full;
        mem[6][8:3]  <= rx_fifo_counter;
        mem[7]       <= rx_fifo_data_out;
        mem[4][2]    <= rx_busy;
        mem[4][7]    <= rx_new_data;
        mem[4][6]    <= rx_frame_error;

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
    mem[0][0]    <= 1'b1; // set reset bit to default value
    mem[4][0]    <= 1'b1; // set reset bit to default value
    mem[0][10:6] <= 5'b00111; // set bits per word register to default value
    mem[4][12:8] <= 5'b00111; // set bits per word register to default value
end

wire        tx_transfer_en;
wire        rx_transfer_en;
reg  [15:0] tx_fifo_data_out;
wire        tx_fifo_empty;
wire        tx_fifo_full;
wire [5:0]  tx_fifo_counter;
wire        tx_busy;
wire [15:0] rx_data_out;
wire        rx_busy;
wire        rx_new_data;
wire        rx_frame_error;
wire        rx_fifo_empty;
wire        rx_fifo_full;
wire [5:0]  rx_fifo_counter;
wire [15:0] rx_fifo_data_out;

assign tx_transfer_en = (mem[0][1] && !tx_busy && !tx_fifo_empty) ? 1'b1 : 1'b0;
assign rx_transfer_en = (mem[4][1] && rx_new_data && !rx_fifo_full) ? 1'b1 : 0'b0;

assign pmod1[2] = rx_new_data;
assign pmod1[3] = rx_busy;

assign led[0] = tx_fifo_empty;
assign led[1] = rx_fifo_empty;
assign led[2] = tx_busy;
assign led[3] = rx_busy;

fifo tx_fifo (
    .clk(clk),
    .rst(mem[0][0]),
    .in(mem[3]),
    .out(tx_fifo_data_out),
    .wr_en_in(mem[2][0]),
    .rd_en_in(tx_transfer_en),
    .empty(tx_fifo_empty),
    .full(tx_fifo_full),
    .counter(tx_fifo_counter),
);

uart_tx uart1_tx (
    .rst(mem[0][0]),
    .data_in(tx_fifo_data_out),
    .wr_en(tx_transfer_en),
    .clk(clk),
    .tx(pmod1[0]),
    .busy(tx_busy),
    .bits_per_word(mem[0][10:6]),
    .clk_div(mem[1]),
    .parity_en(mem[0][3]),
    .parity_evan_odd(mem[0][4]),
    .two_stop_bit(mem[0][5]),
);

fifo rx_fifo (
    .clk(clk),
    .rst(mem[4][0]),
    .in(rx_data_out),
    .out(rx_fifo_data_out),
    .wr_en_in(rx_transfer_en),
    .rd_en_in(mem[6][0]),
    .empty(rx_fifo_empty),
    .full(rx_fifo_full),
    .counter(rx_fifo_counter),
);

uart_rx uart1_rx (
    .clk(clk),
    .rst(mem[4][0]),
    .clk_div(mem[5]),
    .data_out(rx_data_out),
    .rx(pmod2[0]),
    .busy(rx_busy),
    .new_data(rx_new_data),
    .frame_error(rx_frame_error),
    .bits_per_word(mem[4][12:8]),
    .parity_en(mem[4][3]),
    .parity_evan_odd(mem[4][4]),
    .two_stop_bit(mem[4][5]),
);

endmodule

/*
 * memory map
 * offset | register name               
 *--------+--------------------
 *    0   | uart tx setup     
 *    2   | uart tx clock divider    
 *    4   | uart tx fifo setup
 *    6   | uart tx fifo data input
 *    8   | uart rx setup
 *    10  | uart rx clock divider
 *    12  | uart rx fifo setup
 *    14  | uart rx fifo data output
 *
 * uart tx setup register (0x00)
 *   bit  |  default |      |  destination
 *--------+----------+------+-----------------------
 *    0   |     1    |  R/W | reset uart and fifo clr this bit to enable controller 
 *    1   |     0    |  R/W | enable send
 *    2   |     0    |  RO  | busy
 *    3   |     0    |  R/W | parity enable
 *    4   |     0    |  R/W | parity type 0 = evan 1 = odd
 *    5   |     0    |  R/W | two stop bit enable
 *   10-6 |     7    |  R/W | bits per word (numer of bits per word - 1)
 *
 * uart tx clock divider (0x02)
 *   bit  | default  |      | destination
 *--------+----------+------+---------------------------
 *  15-0  |     0    | R/W  | clock divider 
 *
 * uart tx fifo setup register (0x04)
 *   bit  | default  |      | destination
 *--------+----------+------+---------------------------
 *    0   |     0    | R/W  | generate write to fifo signal (set to 1 and then clr bit)
 *    1   |     0    | RO   | fifo empty
 *    2   |     0    | RO   | fifo full
 *   8-3  |     0    | RO   | fifo counter (number of words in buffer)
 *
 * uart tx data input (0x06)
 *   bit  | default  |      | destination
 *--------+----------+------+---------------------------
 *  15-0  |     0    | R/W  | data to send 
 *
 * uart rx setup register (0x08)
 *   bit  |  default |      |  destination
 *--------+----------+------+-----------------------
 *    0   |     1    |  R/W | reset uart and fifo clr this bit to enable controller 
 *    1   |     0    |  R/W | enable receive
 *    2   |     0    |  RO  | busy
 *    3   |     0    |  R/W | parity enable
 *    4   |     0    |  R/W | parity type 0 = evan 1 = odd
 *    5   |     0    |  R/W | two stop bit enable
 *    6   |     0    |  R/W | frame error
 *    7   |     0    |  RO  | new data to read
 *   12-8 |     7    |  R/W | bits per word (numer of bits per word - 1)
 *
 * uart rx clock divider (0x0A)
 *   bit  | default  |      | destination
 *--------+----------+------+---------------------------
 *  15-0  |     0    | R/W  | clock divider 
 *
 * uart rx fifo setup register (0x0C)
 *   bit  | default  |      | destination
 *--------+----------+------+---------------------------
 *    0   |     0    | R/W  | generate write to fifo signal (set to 1 and then clr bit)
 *    1   |     0    | RO   | fifo empty
 *    2   |     0    | RO   | fifo full
 *   8-3  |     0    | RO   | fifo counter (number of words in buffer)
 *
 * uart rx data output (0x0E)
 *   bit  | default  |      | destination
 *--------+----------+------+---------------------------
 *  15-0  |     0    | R/W  | data to send 
 *
 */
