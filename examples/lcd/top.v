module top(input        clk,
           output [3:0] led,
           output       r,
           output       g,
           output       b,
           output       pclk,
           output       de,
           output       disp_on);

//counter in divider 50Mhz/6-> 8,333Mhz
reg [6:0] c = 0;

parameter TDEH = 480;  
parameter TDEL = 256;
parameter TDEB = 45;  
parameter TDE = 272;  

// Horizontal and vertical counter
reg [9:0] Hcount;
reg [8:0] Vcount;

reg clk10_out;
reg [16:0] pixaddr;

wire clk_50m;
wire lock;

SB_PLL40_CORE #(
    .FEEDBACK_PATH("SIMPLE"),
    .PLLOUT_SELECT("GENCLK"),
    .DIVR(4'b0000),
    .DIVF(7'b0000111),
    .DIVQ(3'b100),
    .FILTER_RANGE(3'b101)
) uut (
    .LOCK(lock),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .REFERENCECLK(clk),
    .PLLOUTCORE(clk_50m)
);

always @(posedge clk_50m)
begin
    if (c < 3) begin
        c = c+1;
        clk10_out = 1'b1;	 
    end else if (c>=3 && c<=4) begin
        c = c+1;
        clk10_out = 1'b0;
    end else begin
        c = 0;
    end
end

always @(posedge clk10_out)
begin
    if (Hcount < TDEH && Vcount < TDE) begin
        pixaddr = (Vcount * 480) + Hcount;
    end
	
    if  (Hcount < (TDEH+TDEL)) begin
        Hcount = Hcount + 1;
    end	else begin
        if (Vcount < (TDE+TDEB)) begin
	    Vcount = Vcount + 1;
	end else begin
	    Vcount = 0;				
        end
        Hcount = 0;
    end
end

assign de = ((Hcount < TDEH) && (Vcount < TDE)) ? 1'b1 : 1'b0; 
assign pclk = clk10_out;

assign r = ((Hcount > 0) && (Hcount <= 160)) ? 1'b1 : 1'b0;
assign g = ((Hcount > 160) && (Hcount <= 320)) ? 1'b1 : 1'b0;
assign b = ((Hcount > 320) && (Hcount <= 480)) ? 1'b1 : 1'b0;
assign disp_on = 1'b1;

endmodule
