module bus (
    // MATER INTERFACE
    input    address,
    input    cs,

    // PORT
    output [NUMBER_OF_DEVICE-1:0] cso,
);


parameter NUMBER_OF_DEVICE = 4;
parameter DEVICE_ADDR_WIDTH = 14;
parameter BUS_ADDR_WIDTH = 2

wire [BUS_ADDR_WIDTH-1:0] bus_addr;
wire [DEVICE_ADDR_WIDTH-1:0] device_mem_addr
wire [NUMBER_OF_DEVICE-1:0] csn;

assign bus_addr = address[DEVICE_ADDR_WIDTH+BUS_ADDR_WIDTH-1:DEVICE_ADDR_WIDTH];
assign device_mem_addr = address[DEVICE_ADDR_WIDTH-1:0];

assign csn = (bus_addr == 2'b00) ? 1 :
             (bus_addr == 2'b01) ? 2 :
             (bus_addr == 2'b10) ? 4 : 
                                   8; 

assign cso = (!cs) ? !csn : 4'b1111;

endmodule
