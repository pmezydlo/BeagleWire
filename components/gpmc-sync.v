module gpmc_sync (input                    clk,
                  inout  [15:0]            gpmc_ad,
                  input                    gpmc_advn,
                  input                    gpmc_csn1,
                  input                    gpmc_wein,
                  input                    gpmc_oen,
                  input                    gpmc_clk,
                  inout                    data,
                  output                   busy,
                  input                    cs,
                  input                    oe,
                  input                    we,
                  input  [ADDR_WIDTH-1:0]  addr);
         
parameter ADDR_WIDTH = 4;
parameter DATA_WIDTH = 16;
parameter RAM_DEPTH = 1 << ADDR_WIDTH; 

reg [ADDR_WIDTH-1:0] gpmc_addr;
reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH];
reg [DATA_WIDTH-1:0] gpmc_data_out;
wire [DATA_WIDTH-1:0] gpmc_data_in;
wire busy;

assign busy = !gpmc_csn1;

reg cs;
reg oe;
reg we;
reg [ADDR_WIDTH-1:0] addr;
wire [DATA_WIDTH-1:0] data_out;
assign data = (!cs && !oe && we) ? data_out : 16'bz;

initial begin
    cs <= 1'b1;
    oe <= 1'b1;
    we <= 1'b1;
    addr <= 0;
    data_out <= 0;
    gpmc_addr <= 3'b0;
    gpmc_data_out <= 16'b0;
end

SB_IO # (
    .PIN_TYPE(6'b1010_01),
    .PULLUP(1'b 0)
) gpmc_ad_io [15:0] (
    .PACKAGE_PIN(gpmc_ad),
    .OUTPUT_ENABLE(!gpmc_csn1 && gpmc_advn && !gpmc_oen && gpmc_wein),
    .D_OUT_0(gpmc_data_out),
    .D_IN_0(gpmc_data_in)
);

always @ (negedge gpmc_clk)
begin : GPMC_LATCH_ADDRESS   
    if (!gpmc_csn1 && !gpmc_advn && gpmc_wein && gpmc_oen)
        gpmc_addr <= gpmc_data_in[ADDR_WIDTH-1:0];
end

always @ (negedge gpmc_clk)
begin : WRITE_DATA   
    if (!gpmc_csn1) begin
        if (gpmc_advn && !gpmc_wein && gpmc_oen)
            mem[gpmc_addr] <= gpmc_data_in;
    end else begin
        if (!cs && !we && oe)
            mem[addr] <= data;
    end
end

always @ (negedge gpmc_clk)
begin : READ_DATA   
    if (!gpmc_csn1) begin 
        if (gpmc_advn && gpmc_wein && !gpmc_oen)
            gpmc_data_out <= mem[gpmc_addr];
    end else begin
        if (!cs && we && !oe)
            data_out <= mem[addr];
    end
end

endmodule
