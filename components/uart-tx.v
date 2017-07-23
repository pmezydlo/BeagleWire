module uart_tx (input    [15:0]   data_in,
                input            wr_en,
                input            clk_100m,
                output           tx,
                output           tx_busy,
                input            clken,
                input     [4:0]  bits_per_word,
                output           tx_new_data);

reg tx;

localparam IDLE      = 3'b000;
localparam START     = 3'b001;
localparam VER_START = 3'b010;
localparam DATA      = 3'b011;
localparam STOP      = 3'b100;

reg [15:0] data      = 16'b0000_0000_0000_0000;
reg [4:0]  bit_pos   = 3'b000;
reg [3:0]  state     = IDLE;

assign tx_busy = (state != IDLE) ? 1'b1 : 1'b0;

always @(posedge clk_100m) begin
    case (state)
        IDLE: begin
            if (wr_en) begin
                state <= VER_START;
                data <= data_in;
                bit_pos <= 3'h0;
            end
        end

        VER_START: begin
            if (wr_en == 1'b0) begin
                state <= START;
                tx_new_data <= 1'b0;
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
                if (bit_pos == bits_per_word)
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
                tx_new_data <= 1'b1;
            end
        end

        default: begin
            tx <= 1'b1;
            state <= IDLE;
        end
    endcase
end

endmodule
