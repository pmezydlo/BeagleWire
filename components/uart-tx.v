module uart_tx(input wire [7:0] data_in,
               input wire wr_en,
               input wire clk_100m,
               output reg tx,
               output wire tx_busy);

wire clk_en;

initial begin
    t = 1'b1;
end

parameter IDLE   = 2'b00;
parameter START  = 2'b01;
parameter DATA   = 2'b10;
parameter STOP   = 2'b11;

parameter COUNTER_MAX = 100_000_000 / 9600;
reg [13:0] counter = 0;

reg [7:0] data = 8'b0000_0000;
reg [2:0] bit_pos = 3'b000;
reg [1:0] state = IDLE;

always @(posedge clk_100m) begin
    if (counter == COUNTER_MAX) begin
        
    end else begin
        
    end
        
end

always @(posedge clk_100m) begin
    case (state)
        IDLE: begin
            if (wr_en) begin
                state <= START;
                data <= data_in;
                bit_pos <= 3'h0;
            end
        end

        START: begin
            if (clken) begin
                tx <= 1'b0;
                state <= DATA;
            end
        end

        DATA: begin
            if (clken) begin
                if (bit_pos == 3'h7)
                    state <= STOP;
                else
                    bit_pos <= bit_pos + 3'h1;
                tx <= data[bit_pos];
            end
        end

        STOP: begin
            if (clken) begin
                tx <= 1'b1;
                state <= IDLE;
            end
        end

        default: begin
            tx <= 1'b1;
            state <= IDLE;
        end
    endcase
end

endmodule
