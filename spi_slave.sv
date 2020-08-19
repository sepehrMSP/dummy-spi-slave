//probable bugs 
// - position of write_en
`define SERIAL_OUT_WIDTH 24
 
module spi_slave //reciever
#(parameter SPI_MODE = 0)
(
    MISO,
    MOSI,
    SCLK,
    CSn,

    data_out,
    is_full,
    write_en,
    write_clk,

    data_in,
    is_empty,
    read_en,
    read_clk
);
    output MISO;
    input MOSI;
    input SCLK;
    input CSn;
    //write to async fifo
    output [`SERIAL_OUT_WIDTH-1:0] data_out;
    input is_full;
    output write_en;
    output write_clk;
    //read from async fifo
    input [`SERIAL_OUT_WIDTH-1:0] data_in;
    input is_empty;
    output read_en;
    output read_clk;

    
    wire CPOL;
    wire CPHA;
    wire clock;
    wire CS;

    reg [7:0] rx_byte_spi = 0, tx_byte_spi = 0;
    reg [`SERIAL_OUT_WIDTH-1:0] serial_out_data = 0;
    reg write_en = 0;
    reg MISO;
    reg read_en;

    int rx_byte_spi_counter = 0, tx_byte_spi_counter = 0;
    int serial_out_data_counter = 0, serial_in_data_counter = 0;

    ///////////////////////////////////////////////////////////////
    assign CS = ~CSn;

    assign write_clk = SCLK;
    assign read_clk = SCLK;
    assign data_out = serial_out_data;


    assign CPHA = (SPI_MODE == 1) | (SPI_MODE == 3);
    assign CPOL = (SPI_MODE == 2) | (SPI_MODE == 3);
    assign polaritated_clock = CPOL ? ~SCLK : SCLK;
    //in our code we assume that reading is always at posedge of clock and writing
    //is always at negedge of clock. so for simplicity we use a read_clock which is 
    //clock phase inside itself
    assign read_clock = CPHA ? ~polaritated_clock : polaritated_clock;
    

    //recieve slave
    always@(posedge read_clock, posedge CSn)begin
        if(CSn)begin
            rx_byte_spi = 0;
            rx_byte_spi_counter = 0;
            write_en = 0;
        end
        else begin
            write_en = 0;
            rx_byte_spi = {rx_byte_spi[6:0], MOSI};
            serial_out_data = {serial_out_data[`SERIAL_OUT_WIDTH-2:0], MOSI};
            serial_out_data_counter = serial_out_data_counter + 1;
            if (serial_out_data_counter == `SERIAL_OUT_WIDTH)begin
                write_en = 1;
                serial_out_data_counter = 0;
            end
        end
    end


    //send slave
    always@(negedge read_clock, negedge CS)begin
        if(CSn == 1)begin
           read_en = 0;
        end 
        else begin
            read_en = 0;
            MISO = tx_byte_spi[7];
            tx_byte_spi = tx_byte_spi << 1;
            tx_byte_spi_counter = tx_byte_spi_counter + 1;
            if (tx_byte_spi_counter == 8)begin
                tx_byte_spi_counter = 0;
                tx_byte_spi = data_in[serial_in_data_counter*8 +: 8];
                serial_in_data_counter = serial_in_data_counter + 1;
                if (serial_in_data_counter == (`SERIAL_OUT_WIDTH/8))begin
                    serial_in_data_counter= 0;
                    read_en = 1;
                end
            end
        end
    end

endmodule

/*
`timescale 1 ns / 1 ps

module mySPI_Tx_AXIS_v1_0_S00_AXIS #
(
    // Users to add parameters here
    parameter integer width = 8,
    parameter integer clkdiv= 4,

    // User parameters ends
    // Do not modify the parameters beyond this line

    // AXI4Stream sink: Data Width
    parameter integer C_S_AXIS_TDATA_WIDTH  = 32
)
(
    // Users to add ports here
    output wire sclk,
    output reg mosi = 0,
    output wire ss,

    // User ports ends
    // Do not modify the ports beyond this line

    // AXI4Stream sink: Clock
    input wire  S_AXIS_ACLK,
    // AXI4Stream sink: Reset
    input wire  S_AXIS_ARESETN,
    // Ready to accept data in
    output wire  S_AXIS_TREADY,
    // Data in
    input wire [C_S_AXIS_TDATA_WIDTH-1 : 0] S_AXIS_TDATA,
    // Byte qualifier
    input wire [(C_S_AXIS_TDATA_WIDTH/8)-1 : 0] S_AXIS_TSTRB,
    // Indicates boundary of last packet
    input wire  S_AXIS_TLAST,
    // Data is in valid
    input wire  S_AXIS_TVALID
);

// This holds the shift register
reg [width-1 : 0] buffer = 0;
reg buffer_full = 0;

// Counts the bits
reg [5:0] bitcounter = 0;
    
// Makes things slower
reg [clkdiv-1:0] prescaler = 0;

// State machine states
localparam IDLE = 0;
localparam S1 = 1;
localparam S2 = 2;
localparam S3 = 3;

// Default state is IDLE
reg [1:0] state = IDLE;

// Signals we are ready to receive
assign S_AXIS_TREADY = !buffer_full;
    
// SPI Clock (data is valid during Low/High transition)
assign sclk = state==S2 || state==S3;
    
// SPI Slave Select
assign ss = state!=IDLE;
    
// This is the main state machine
always @(posedge S_AXIS_ACLK) begin
    // There is only one important rule for an AXI Stream interface:
    // If during the rising clock, S_AXIS_TVALID==1 and S_AXIS_TREADY==1, then we have to accept the data.  
    if (S_AXIS_TVALID==1 && S_AXIS_TREADY==1) begin
        buffer <= S_AXIS_TDATA[width-1 : 0];
        buffer_full = 1;
    end else if (state==S3 && prescaler==1) begin
        buffer_full = 0;
    end
    
    prescaler <= prescaler+1;
    if (prescaler==0) begin // The state transitions are synchronized to the SPI bit clock
        case(state)
            IDLE:   begin // ss=0, sclk=0, mosi=0
                        mosi <= 0;
                        if (buffer_full==1) begin
                            mosi <= buffer[width-1];
                            bitcounter <= 1;
                            state <= S1;
                        end
                    end
            S1:     begin // ss=1, sclk=0
                        if ( bitcounter==width ) begin
                            state <= S3;
                        end else begin
                            state <= S2;
                            buffer <= buffer<<1;
                        end
                    end
            S2:     begin // ss=1, sclk=1
                        state <= S1;
                        mosi <= buffer[width-1];
                        bitcounter <= bitcounter+1;
                    end
            S3:     begin // ss=1, sclk=1 (last bit)
                        if (buffer_full==1) begin
                            mosi <= buffer[width-1];
                            bitcounter <= 1;
                            state <= S1;
                        end else begin
                            state <= IDLE;
                        end
                    end
            default:begin
                        state <= IDLE;
                    end
        endcase
    end
end

endmodule
*/