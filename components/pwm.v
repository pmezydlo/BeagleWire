module pwm (input                   en,
            input [COUNTER_WIDTH:0] period,
            input [COUNTER_WIDTH:0] duty_cycle,
            input                   polarity,
            input                   clk,
            output                  out, 
           );

parameter COUNTER_WIDTH = 32;
reg out_pwm;
reg [COUNTER_WIDTH:0] count;

assign out = (polarity) ? out_pwm : !out_pwm;

always @ (posedge clk)
begin
    if (!en) begin
        out_pwm <= 1'b0;        
    end else begin

        if (count < period) begin
            count <= count + 1'b1;
        end else begin
            count <= 0;
        end

        if (count < duty_cycle) begin
            out_pwm <= 1;
        end else begin
            out_pwm <= 0;
        end
    end
end

endmodule
