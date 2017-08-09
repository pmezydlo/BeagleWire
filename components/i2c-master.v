module i2c_master (input clk,
                   input rst,
               
                   inout scl,
                   inout sda,
               
                   input scl_enable);


parameter BUS_CLK = 400_000;
parameter CLK_FREQ = 100_000_000;
localparam DIVIDER = (CLK_FREQ/BUS_CLK)/4;

reg streach;
reg [9:0] count;

reg data_clk;
reg data_clk_prev;
wire scl_in;
reg scl_clk;
reg scl_enable;
wire sda_in;
reg sda_enable;

always @ (posedge clk or posedge rst)
begin
    if (rst) begin
        streach <= 0;
        count <= 0;
    end else begin
        data_clk_prev <= data_clk;

        if (count == DIVIDER*4-1) begin
            count <= 0;
        end else begin
            count <= count + 1;
        end

        if (count > 0 && count < DIVIDER-1) begin
            scl_clk <= 1'b0;
            data_clk <= 1'b0;
        end else if (count > DIVIDER && count < DIVIDER*2-1) begin
            scl_clk <= 1'b0;
            data_clk <= 1'b1;
        end else if (count > DIVIDER*2 && count < DIVIDER*3-1) begin
            scl_clk <= 1'b1;
            if (scl_in == 1'b0)
                streach <= 1'b1;
            else
                streach <= 1'b0;
            data_clk <= 1'b1;
        end else begin
            scl_clk <= 1'b1;
            data_clk <= 1'b0;
        end
    end
end

//Tri-State buffer controll
SB_IO # (
    .PIN_TYPE(6'b1010_01),
    .PULLUP(1'b0)
) scl_io (
    .PACKAGE_PIN(scl),
    .OUTPUT_ENABLE(scl_enable == 1'b1 && scl_clk == 1'b0),
    .D_OUT_0(1'b0),
    .D_IN_0(scl_in),
);

//Tri-State buffer controll
SB_IO # (
    .PIN_TYPE(6'b1010_01),
    .PULLUP(1'b0)
) sda_io (
    .PACKAGE_PIN(sda),
    .OUTPUT_ENABLE(sda_enable == 1'b1),
    .D_OUT_0(1'b0),
    .D_IN_0(sda_in),
);

endmodule
