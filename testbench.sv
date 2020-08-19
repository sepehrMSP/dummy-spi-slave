module testbench();

    reg MISO, MOSI, SCLK, CSn;
    wire [7:0] data_out;
    reg is_full;
    wire write_en;
    wire write_clk, read_clk;
    reg [23:0] data_in;
    reg is_empty;
    wire read_en;


    spi_slave slave (   .MISO(MISO),
                        .MOSI(MOSI),
                        .SCLK(SCLK),
                        .CSn(CSn),
                        
                        .data_out(data_out),
                        .is_full(is_full),
                        .write_en(write_en),
                        .write_clk(write_clk),

                        .data_in(data_in),
                        .is_empty(is_empty),
                        .read_en(read_en),
                        .read_clk(read_clk)                        
                    );

    always #5 SCLK = ~SCLK;

    int i;

    initial begin
        data_in = 0;
        MOSI = 0;
        CSn = 1;
        SCLK = 0;
        #17
        CSn = 0;
        // @(posedge SCLK);
        // MOSI = 1; // 1
        // @(posedge SCLK)
        // MOSI = 1; // 2
        // @(posedge SCLK)
        // MOSI = 1; // 3
        // @(posedge SCLK)
        // MOSI = 1; // 4
        // @(posedge SCLK)
        // MOSI = 0; // 5
        // @(posedge SCLK)
        // MOSI = 0; // 6
        // @(posedge SCLK)
        // MOSI = 1; // 7
        // @(posedge SCLK)
        // MOSI = 0; // 8
        // @(posedge SCLK)
        // MOSI = 0; // 9
        // @(posedge SCLK)
        // MOSI = 1; // 10
        // @(posedge SCLK)
        // MOSI = 1; // 11
        // @(posedge SCLK)
        // MOSI = 0; // 12
        // @(posedge SCLK)
        // MOSI = 1; // 13
        // @(posedge SCLK)
        // MOSI = 0; // 14
        // @(posedge SCLK)
        // MOSI = 0; // 15
        // @(posedge SCLK)
        // MOSI = 0; // 16
        // @(posedge SCLK)
        // MOSI = 0; // 17
        // @(posedge SCLK)
        // MOSI = 1; // 18
        data_in = 24'b_1111_0000_1111_0000_1111_0000;
        #200
        CSn = 1;
        #15
        data_in = 24'b_1010_0101_1010_0101_1010_0101;
        #2
        CSn = 0;
        

    end


















endmodule