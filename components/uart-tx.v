module uart_tx (input    [15:0]   data_in,
                input    [15:0]   clk_div,
                input             wr_en,
                input             clk,
                output            tx,
                output            busy,
                input     [4:0]   bits_per_word,
                input             rst,
                input             parity_en,
                input             parity_evan_odd,
                input             two_stop_bit);

localparam IDLE      = 3'b000;
localparam START     = 3'b001;
localparam VER_START = 3'b010;
localparam DATA      = 3'b011;
localparam STOP      = 3'b100;
localparam STOP2     = 3'b101;
localparam PARITY    = 3'b110;
localparam END       = 3'b111;

reg [15:0] data;
reg [4:0]  bit_pos;
reg [3:0]  state;
reg        tx;
reg        new_data;
reg [15:0] counter;
reg        clken;
reg [2:0]  stop_counter;
reg        parity_bit;

assign busy = (state != IDLE) ? 1'b1 : 1'b0;

always @(posedge clk)
begin
    if (rst) begin
        clken <= 0;
        counter <= 0;
    end else begin
       if (counter == clk_div) begin
           clken <= 1'b1;
           counter <= 1;
       end else begin
           clken <= 1'b0;
           counter <= counter + 1;
       end
    end
end

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        bit_pos <= 3'b000;
        tx <= 1'b1;
    end else begin
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
                    data <= data_in;
                end
            end

            START: begin
                if (clken) begin
                    tx <= 1'b0;
                    state <= DATA;
                    if (parity_evan_odd)
                        parity_bit <= 1'b0;
                    else
                        parity_bit <= 1'b1;
                end
            end

            DATA: begin
                if (clken) begin
                    if (bit_pos == bits_per_word)
                        if (parity_en)
                            state <= PARITY;
                        else
                            state <= STOP;
                    else
                        bit_pos <= bit_pos + 3'h1;

                    tx <= data[bit_pos];
                    parity_bit <= parity_bit ^ data[bit_pos];
                end
            end

            PARITY: begin
                if (clken) begin
                    tx <= parity_bit;
                    state <= STOP;
                end
            end

            STOP: begin
                if (clken) begin
                    tx <= 1'b1;

                    if (two_stop_bit)
                        state <= STOP2;
                    else
                        state <= END;
                end
            end

            STOP2: begin
                if (clken)
                    state <= END;
            end

            END: begin
                if (clken) 
                    state <= IDLE;
            end

            default: begin
                tx <= 1'b1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule
