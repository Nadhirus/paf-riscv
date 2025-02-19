`timescale 1ns / 1ps

module ram_axi_tb;
  parameter DATA_WIDTH      = 32;
  parameter ADDR_WIDTH      = 10;
  parameter NUM_CORES       = 2;
  parameter MASTER_ID_WIDTH = $clog2(NUM_CORES);

  // Clock and Reset
  reg axi_aclk;
  reg axi_aresetn;

  // AXI signals
  reg  [ADDR_WIDTH-1:0] axi_awaddr;
  reg  [2:0]            axi_awprot;
  reg                   axi_awvalid;
  wire                  axi_awready;
  
  reg  [DATA_WIDTH-1:0] axi_wdata;
  reg  [(DATA_WIDTH/8)-1:0] axi_wstrb;
  reg                   axi_wvalid;
  wire                  axi_wready;

  wire [1:0]            axi_bresp;
  wire                  axi_bvalid;
  reg                   axi_bready;

  reg  [ADDR_WIDTH-1:0] axi_araddr;
  reg  [2:0]            axi_arprot;
  reg                   axi_arvalid;
  wire                  axi_arready;

  wire [DATA_WIDTH-1:0] axi_rdata;
  wire [1:0]            axi_rresp;
  wire                  axi_rvalid;
  reg                   axi_rready;

  reg  [1:0]            axi_exclusive_op;
  reg  [MASTER_ID_WIDTH-1:0] axi_master_id;

  // Instantiate the RAM module
  ram_axi #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_CORES(NUM_CORES)
  ) dut (
    .axi_aclk(axi_aclk),
    .axi_aresetn(axi_aresetn),
    .axi_awaddr(axi_awaddr),
    .axi_awprot(axi_awprot),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    .axi_wdata(axi_wdata),
    .axi_wstrb(axi_wstrb),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),
    .axi_bresp(axi_bresp),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_araddr(axi_araddr),
    .axi_arprot(axi_arprot),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    .axi_rdata(axi_rdata),
    .axi_rresp(axi_rresp),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    .axi_exclusive_op(axi_exclusive_op),
    .axi_master_id(axi_master_id)
  );

  // Clock Generation
  always #5 axi_aclk = ~axi_aclk;

  // Test Procedure
  initial begin
    axi_aclk = 0;
    axi_aresetn = 0;
    axi_awvalid = 0;
    axi_wvalid = 0;
    axi_bready = 1;
    axi_arvalid = 0;
    axi_rready = 1;
    axi_exclusive_op = 2'b00;
    axi_master_id = 0;

    // Reset Sequence
    #10 axi_aresetn = 1;
    
    // Test normal write operation
    axi_awaddr = 10'h3F;
    axi_awvalid = 1;
    axi_wdata = 32'hDEADBEEF;
    axi_wstrb = 4'b1111;
    axi_wvalid = 1;
    wait(axi_awready && axi_wready);
    axi_awvalid = 0;
    axi_wvalid = 0;
    wait(axi_bvalid);
    assert(axi_bresp == 2'b00) else $display("ERROR: Write failed");
    axi_bready = 1;
    
    // Test LR/SC operation (success case)
    axi_master_id = 1;
    axi_exclusive_op = 2'b01; // Load-Reserved
    axi_araddr = 10'h3F;
    axi_arvalid = 1;
    wait(axi_arready);
    axi_arvalid = 0;
    wait(axi_rvalid);
    axi_rready = 1;
    
    axi_exclusive_op = 2'b10; // Store-Conditional
    axi_awaddr = 10'h3F;
    axi_awvalid = 1;
    axi_wdata = 32'h12345678;
    axi_wvalid = 1;
    wait(axi_awready && axi_wready);
    axi_awvalid = 0;
    axi_wvalid = 0;
    wait(axi_bvalid);
    assert(axi_bresp == 2'b00) else $display("ERROR: SC failed unexpectedly");
    axi_bready = 1;
    
    // Test LR/SC operation (failure case)
    axi_master_id = 0; // Another master writes in between
    axi_awaddr = 10'h3F;
    axi_awvalid = 1;
    axi_wdata = 32'hAABBCCDD;
    axi_wvalid = 1;
    wait(axi_awready && axi_wready);
    axi_awvalid = 0;
    axi_wvalid = 0;
    wait(axi_bvalid);
    axi_bready = 1;
    
    axi_master_id = 1;
    axi_exclusive_op = 2'b10; // Store-Conditional
    axi_awaddr = 10'h3F;
    axi_awvalid = 1;
    axi_wdata = 32'h87654321;
    axi_wvalid = 1;
    wait(axi_awready && axi_wready);
    axi_awvalid = 0;
    axi_wvalid = 0;
    wait(axi_bvalid);
    assert(axi_bresp == 2'b10) else $display("ERROR: SC should have failed");
    axi_bready = 1;
    
    $display("TEST COMPLETED");
    $stop;
  end
endmodule
