`timescale 1ns / 1ps

`define SIMULATION
module rom_tb;

  // Parameters
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 10;

  // Signals
  reg [(ADDR_WIDTH-1):0] addr;
  reg clk;
  wire [(DATA_WIDTH-1):0] rdata;
  wire rdata_valid;

  // Instantiate the ROM module
  rom #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
  ) uut (
    .addr(addr),
    .clk(clk),
    .rdata(rdata),
    .rdata_valid(rdata_valid)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10 ns clock period
  end

  // Test sequence
  initial begin
    // Initialize address
    addr = 0;
    
    // Wait for the ROM to initialize
    #10;
    
    // Apply a sequence of addresses
    $display("Starting test...");
    repeat (4) begin
      @(posedge clk);
      #1 addr = addr + 1; // Increment address
      @(posedge clk);
      #1 $display("Address: %d, Data: %h, Valid: %b", addr, rdata, rdata_valid);
    end

  end

endmodule
