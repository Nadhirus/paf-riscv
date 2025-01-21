`define SIMULATION
module tb_RISC;

    // Parameters
    logic clk;
    logic reset_n;

    // DUT Signals
    logic [31:0] d_address;
    logic [31:0] d_data_read;
    logic [31:0] d_data_write;
    logic [ 3:0] d_data_wstrb;
    logic d_write_enable;
    logic d_data_valid;
    logic [31:0] i_address;
    logic [31:0] i_data_read;
    logic i_data_valid;

    // Instantiate the DUT (Device Under Test)
    RISC uut (
        .clk(clk),
        .reset_n(reset_n),
        .d_address(d_address),
        .d_data_read(d_data_read),
        .d_data_write(d_data_write),
        .d_data_wstrb(d_data_wstrb),
        .d_write_enable(d_write_enable),
        .d_data_valid(d_data_valid),
        .i_address(i_address),
        .i_data_read(i_data_read),
        .i_data_valid(i_data_valid)
    );

    // ROM instance
    rom #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10)
    ) rom_inst (
        .addr(i_address[11:2]),  // Assuming word-aligned addresses
        .clk(clk),
        .rdata(i_data_read),
        .rdata_valid(i_data_valid)
    );

    // RAM instance
    ram #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10)
    ) ram_inst (
        .wdata(d_data_write),
        .addr(d_address[11:2]),  // Assuming word-aligned addresses
        .we(d_write_enable),
        .clk(clk),
        .rdata(d_data_read),
        .rdata_valid(d_data_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        reset_n = 0;
        #20;
        reset_n = 1;
    end

    // Simulation control
    initial begin
        // Run for a limited time and then finish
        #1000;
    end

    // // Monitor outputs for debugging
    // initial begin
    //     $monitor("Time = %0t, PC = %h, Data Addr = %h, Data Write = %h, Write Enable = %b", 
    //              $time, i_address, d_address, d_data_write, d_write_enable);
    // end

endmodule
