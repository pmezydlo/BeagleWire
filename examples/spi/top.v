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
            output [7:0]  pmod2,
            output [7:0]  pmod3,
            output [7:0]  pmod4);

parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

wire oe;
wire we;
wire cs;
reg [ADDR_WIDTH-1:0]  address;
reg [DATA_WIDTH-1:0]  data_out;
wire[DATA_WIDTH-1:0]  data_in;
reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH];

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
    .address(address),
    .data_out(data_out),
    .data_in(data_in),
);

always @ (posedge clk)
begin : MEM_WRITE
    if (!cs && !we && oe) begin
        mem[address] <= data_in;
    end
end

always @ (posedge clk)
begin : MEM_READ
    if (!cs && we && !oe) begin
        data_out <= mem[address];
    end
end

assign led = mem[0][3:0];


/* here should be spi controller
 * memory map
 * offset | name               | 
 *--------+--------------------+
 *    0   | setup register     | 
 *    2   | state register     | 
 *    4   | tranceive register | 
 *    6   | receive register   |
 *
 * setup register
 *   bit  |      
 *--------+--------------------+
 *    0   |  reset controller  |
 *   5-1  |  clock div         |
 *    6   |  send data         |
 *
 * state register
 *   bit  |
 *--------+-----------------------+
 *    0   |  busy                 |
 *    1   |  new data for receive |
 *
 * 
 */
/*
reg reset;
reg start;
reg clk_div[4:0];

spi #(.CLK_DIV(20))
spi_master (
    .clk(clk),
    .rst(1'b0),
    .miso(),
    .mosi(),
    .sck(),
    .start(),
    .data_in(),
    .data_out(),
    .busy(),
    .new_data(),
);

localparam IDLE           = 3'b000,
           SET_RESET      = 3'b001,
           SET_CLOCK      = 3'b010,
           SET_START      = 3'b011,
           SET_SEND_DATA  = 3'b001; 


  */     
       
endmodule
