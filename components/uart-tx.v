module uart_tx (input    [15:0]   data_in,
                input    [15:0]   clk_div,
                input             wr_en,
                input             clk,
                output            tx,
                output            busy,
                input     [4:0]   bits_per_word,
                output            new_data,
                input             rst);

localparam IDLE      = 3'b000;
localparam START     = 3'b001;
localparam VER_START = 3'b010;
localparam DATA      = 3'b011;
localparam STOP      = 3'b100;

reg [15:0] data;
reg [4:0]  bit_pos;
reg [3:0]  state;
reg        tx;
reg        new_data;
reg [15:0] counter;
reg        clken;

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
                    new_data <= 1'b0;
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
                    new_data <= 1'b1;
                end
            end

            default: begin
                tx <= 1'b1;
                state <= IDLE;
            end
        endcase
    end
end

endmodule
