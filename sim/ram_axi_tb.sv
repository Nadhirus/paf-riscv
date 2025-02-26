`timescale 1ns / 1ps

module ram_axi_tb;
  // Parameters
  parameter DATA_WIDTH = 32;
  parameter ADDR_WIDTH = 10;
  parameter NUM_CORES = 4;
  parameter MASTER_ID_WIDTH = $clog2(NUM_CORES);

  // Clock and reset
  logic                       axi_aclk;
  logic                       axi_aresetn;

  // Write Address Channel
  logic [     ADDR_WIDTH-1:0] axi_awaddr;
  logic [                2:0] axi_awprot;
  logic                       axi_awvalid;
  logic                       axi_awready;
  logic [MASTER_ID_WIDTH-1:0] axi_awid;
  logic                       axi_awlock;

  // Write Data Channel
  logic [     DATA_WIDTH-1:0] axi_wdata;
  logic [ (DATA_WIDTH/8)-1:0] axi_wstrb;
  logic                       axi_wvalid;
  logic                       axi_wready;

  // Write Response Channel
  logic [                1:0] axi_bresp;
  logic                       axi_bvalid;
  logic                       axi_bready;
  logic [MASTER_ID_WIDTH-1:0] axi_bid;

  // Read Address Channel
  logic [     ADDR_WIDTH-1:0] axi_araddr;
  logic [                2:0] axi_arprot;
  logic                       axi_arvalid;
  logic                       axi_arready;
  logic [MASTER_ID_WIDTH-1:0] axi_arid;
  logic                       axi_arlock;

  // Read Data Channel
  logic [     DATA_WIDTH-1:0] axi_rdata;
  logic [                1:0] axi_rresp;
  logic                       axi_rvalid;
  logic                       axi_rready;
  logic [MASTER_ID_WIDTH-1:0] axi_rid;

  // Atomic operation lock
  logic [      NUM_CORES-1:0] axi_core_block;

  // Test data and expected results
  logic [     DATA_WIDTH-1:0] expected_data;
  logic [     DATA_WIDTH-1:0] read_data;
  logic                       test_passed;

  // Instantiate the RAM module
  ram_axi #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_CORES(NUM_CORES),
    .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
  ) dut (
    .axi_aclk(axi_aclk),
    .axi_aresetn(axi_aresetn),

    .axi_awaddr(axi_awaddr),
    .axi_awprot(axi_awprot),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    .axi_awid(axi_awid),
    .axi_awlock(axi_awlock),

    .axi_wdata (axi_wdata),
    .axi_wstrb (axi_wstrb),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),

    .axi_bresp(axi_bresp),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_bid(axi_bid),

    .axi_araddr(axi_araddr),
    .axi_arprot(axi_arprot),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    .axi_arid(axi_arid),
    .axi_arlock(axi_arlock),

    .axi_rdata(axi_rdata),
    .axi_rresp(axi_rresp),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    .axi_rid(axi_rid),

    .axi_core_block(axi_core_block)
  );

  // Clock generation
  initial begin
    axi_aclk = 0;
    forever #5 axi_aclk = ~axi_aclk;  // 100MHz clock
  end

  // Task for normal write operation
  task write_data(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data,
                  input [MASTER_ID_WIDTH-1:0] id);
    // Set up write address channel
    axi_awaddr  = addr;
    axi_awprot  = 3'b000;
    axi_awvalid = 1'b1;
    axi_awid    = id;
    axi_awlock  = 1'b0; // Non-exclusive write

    // Set up write data channel
    axi_wdata   = data;
    axi_wstrb   = {(DATA_WIDTH/8){1'b1}}; // All bytes enabled
    axi_wvalid  = 1'b1;
    axi_bready  = 1'b1;

    // Wait for handshake
    wait (axi_awready && axi_wready);
    @(posedge axi_aclk);

    // Clear request signals
    axi_awvalid = 1'b0;
    axi_wvalid  = 1'b0;

    // Wait for response
    wait (axi_bvalid);
    @(posedge axi_aclk);
    axi_bready = 1'b0;

    // Display transaction information
    $display("Time %0t: Normal Write - Address: 0x%h, Data: 0x%h, ID: %0d, Response: %0b", $time,
             addr, data, id, axi_bresp);
  endtask

  // Task for exclusive read operation (LR)
  task exclusive_read(input [ADDR_WIDTH-1:0] addr, input [MASTER_ID_WIDTH-1:0] id,
                      output [DATA_WIDTH-1:0] data);
    // Set up read address channel
    axi_araddr  = addr;
    axi_arprot  = 3'b000;
    axi_arvalid = 1'b1;
    axi_arid    = id;
    axi_arlock  = 1'b1; // Exclusive read
    axi_rready  = 1'b1;

    // Wait for address handshake
    wait (axi_arready);
    @(posedge axi_aclk);
    axi_arvalid = 1'b0;

    // Wait for data
    wait (axi_rvalid);
    data = axi_rdata;
    @(posedge axi_aclk);
    axi_rready = 1'b0;

    // Display transaction information
    $display("Time %0t: Exclusive Read (LR) - Address: 0x%h, Data: 0x%h, ID: %0d, Response: %0b",
             $time, addr, data, id, axi_rresp);
  endtask

  // Task for exclusive write operation (SC)
  task exclusive_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data,
                       input [MASTER_ID_WIDTH-1:0] id, output logic success);
    // Set up write address channel
    axi_awaddr  = addr;
    axi_awprot  = 3'b000;
    axi_awvalid = 1'b1;
    axi_awid    = id;
    axi_awlock  = 1'b1; // Exclusive write

    // Set up write data channel
    axi_wdata   = data;
    axi_wstrb   = {(DATA_WIDTH/8){1'b1}}; // All bytes enabled
    axi_wvalid  = 1'b1;
    axi_bready  = 1'b1;

    // Wait for handshake
    wait (axi_awready && axi_wready);
    @(posedge axi_aclk);

    // Clear request signals
    axi_awvalid = 1'b0;
    axi_wvalid  = 1'b0;

    // Wait for response
    wait (axi_bvalid);
    success = (axi_bresp == 2'b01);  // EXOKAY response means success
    @(posedge axi_aclk);
    axi_bready = 1'b0;

    // Display transaction information
    $display(
      "Time %0t: Exclusive Write (SC) - Address: 0x%h, Data: 0x%h, ID: %0d, Response: %0b, Success: %0d",
      $time, addr, data, id, axi_bresp, success);
  endtask

  // Task for normal read operation (renamed to perform_read)
  task perform_read(input [ADDR_WIDTH-1:0] addr, input [MASTER_ID_WIDTH-1:0] id,
                    output [DATA_WIDTH-1:0] data);
    // Set up read address channel
    axi_araddr  = addr;
    axi_arprot  = 3'b000;
    axi_arvalid = 1'b1;
    axi_arid    = id;
    axi_arlock  = 1'b0; // Non-exclusive read
    axi_rready  = 1'b1;

    // Wait for address handshake
    wait (axi_arready);
    @(posedge axi_aclk);
    axi_arvalid = 1'b0;

    // Wait for data
    wait (axi_rvalid);
    data = axi_rdata;
    @(posedge axi_aclk);
    axi_rready = 1'b0;

    // Display transaction information
    $display("Time %0t: Normal Read - Address: 0x%h, Data: 0x%h, ID: %0d, Response: %0b", $time,
             addr, data, id, axi_rresp);
  endtask

  // Task to perform atomic increment operation using LR/SC
  task atomic_increment(input [ADDR_WIDTH-1:0] addr, input [MASTER_ID_WIDTH-1:0] id,
                        output logic success);
    logic [DATA_WIDTH-1:0] read_val;
    logic [DATA_WIDTH-1:0] new_val;

    // Step a: Load-Reserve
    exclusive_read(addr, id, read_val);

    // Step b: Increment the value
    new_val = read_val + 1;

    // Step c: Store-Conditional
    exclusive_write(addr, new_val, id, success);

    if (success)
      $display(
        "Time %0t: Atomic Increment SUCCESS - Address: 0x%h, Old: 0x%h, New: 0x%h",
        $time,
        addr,
        read_val,
        new_val
      );
    else $display("Time %0t: Atomic Increment FAILED - Address: 0x%h", $time, addr);
  endtask

  // Task to test core blocking feature
  task test_core_blocking(input [ADDR_WIDTH-1:0] addr, input [MASTER_ID_WIDTH-1:0] blocker_id,
                          input [MASTER_ID_WIDTH-1:0] blocked_id);
    logic [DATA_WIDTH-1:0] read_data_blocker;
    logic [DATA_WIDTH-1:0] read_data_blocked;

    // First, ensure no blocks are active
    axi_core_block = '0;

    // Blocker core performs a read to ensure access works
    $display("\nTesting core blocking - Blocker ID: %0d, Blocked ID: %0d", blocker_id, blocked_id);
    perform_read(addr, blocker_id, read_data_blocker);

    // Now activate blocking for other cores
    axi_core_block = (1 << blocker_id);
    $display("Time %0t: Activating block by core %0d (block mask: 0x%h)", $time, blocker_id,
             axi_core_block);

    // Blocked core tries to read
    axi_araddr  = addr;
    axi_arprot  = 3'b000;
    axi_arvalid = 1'b1;
    axi_arid    = blocked_id;
    axi_arlock  = 1'b0;
    axi_rready  = 1'b1;

    // Wait some time to see if it gets blocked
    repeat (5) @(posedge axi_aclk);

    // Check if the read request has been acknowledged
    if (axi_arready) begin
      $display("ERROR: Time %0t: Blocking failed - Core %0d's read was accepted despite block",
               $time, blocked_id);
    end else begin
      $display("Time %0t: Blocking successful - Core %0d's read was blocked", $time, blocked_id);
    end

    // Release the block
    axi_core_block = '0;
    $display("Time %0t: Released block", $time);

    // Complete the read transaction if it was waiting
    wait (axi_arready);
    @(posedge axi_aclk);
    axi_arvalid = 1'b0;

    if (axi_rvalid) begin
      read_data_blocked = axi_rdata;
      @(posedge axi_aclk);
    end

    axi_rready = 1'b0;
  endtask

  // Task to test failed store conditional due to intervening write
  task test_failed_sc(input [ADDR_WIDTH-1:0] addr, input [MASTER_ID_WIDTH-1:0] id1,
                      input [MASTER_ID_WIDTH-1:0] id2);
    logic [DATA_WIDTH-1:0] read_val;
    logic [DATA_WIDTH-1:0] new_val;
    logic success;

    $display("\nTesting failed SC due to intervening write");

    // First core does LR
    exclusive_read(addr, id1, read_val);

    // Second core does a normal write to the same address
    write_data(addr, 32'hDEADBEEF, id2);

    // First core tries SC which should fail
    new_val = read_val + 1;
    exclusive_write(addr, new_val, id1, success);

    if (!success) $display("PASS: SC correctly failed due to intervening write");
    else $display("ERROR: SC should have failed but succeeded");
  endtask

  // Main test sequence
  initial begin
    // Initialize signals
    axi_aresetn   = 1'b0;
    axi_awvalid   = 1'b0;
    axi_wvalid    = 1'b0;
    axi_bready    = 1'b0;
    axi_arvalid   = 1'b0;
    axi_rready    = 1'b0;
    axi_core_block = '0;
    axi_awlock    = 1'b0;
    axi_arlock    = 1'b0;
    test_passed   = 1'b1;

    // Apply reset
    repeat (5) @(posedge axi_aclk);
    axi_aresetn = 1'b1;
    repeat (2) @(posedge axi_aclk);

    $display("\n------------------------ TEST BEGINS ------------------------");

    // Test 1: Basic write and read operations
    $display("\n--- Test 1: Basic Write and Read Operations ---");
    write_data(10'h20, 32'h12345678, 0);
    perform_read(10'h20, 0, read_data);

    if (read_data !== 32'h12345678) begin
      $display("ERROR: Read data mismatch. Expected: 0x%h, Got: 0x%h", 32'h12345678, read_data);
      test_passed = 1'b0;
    end

    // Test 2: LR/SC successful operation (atomic increment)
    $display("\n--- Test 2: LR/SC Successful Operation ---");
    write_data(10'h30, 32'h00000001, 1);

    begin
      logic success;
      atomic_increment(10'h30, 1, success);

      // Verify the increment
      perform_read(10'h30, 1, read_data);
      if (read_data !== 32'h00000002) begin
        $display("ERROR: Atomic increment failed. Expected: 0x%h, Got: 0x%h", 32'h00000002,
                 read_data);
        test_passed = 1'b0;
      end
    end

    // Test 3: LR/SC with failed SC due to intervening write
    $display("\n--- Test 3: LR/SC with Failed SC ---");
    test_failed_sc(10'h40, 2, 3);

    // Verify the memory contains the intervening write's data
    perform_read(10'h40, 2, read_data);
    if (read_data !== 32'hDEADBEEF) begin
      $display("ERROR: Memory contains incorrect data after failed SC. Expected: 0x%h, Got: 0x%h",
               32'hDEADBEEF, read_data);
      test_passed = 1'b0;
    end

    // Test 4: Concurrent operations by different cores
    $display("\n--- Test 4: Concurrent Operations by Different Cores ---");

    // Core 0 writes to address 0x50
    write_data(10'h50, 32'hAAAAAAAA, 0);

    // Core 1 writes to address 0x60
    write_data(10'h60, 32'hBBBBBBBB, 1);

    // Verify both writes
    perform_read(10'h50, 0, read_data);
    if (read_data !== 32'hAAAAAAAA) begin
      $display("ERROR: Concurrent write failed for core 0. Expected: 0x%h, Got: 0x%h",
               32'hAAAAAAAA, read_data);
      test_passed = 1'b0;
    end

    perform_read(10'h60, 1, read_data);
    if (read_data !== 32'hBBBBBBBB) begin
      $display("ERROR: Concurrent write failed for core 1. Expected: 0x%h, Got: 0x%h",
               32'hBBBBBBBB, read_data);
      test_passed = 1'b0;
    end

    // Test 5: Test core blocking functionality
    $display("\n--- Test 5: Core Blocking Functionality ---");
    write_data(10'h70, 32'h11223344, 0);
    test_core_blocking(10'h70, 2, 3);  // Core 2 blocks Core 3

    // Test 6: Multiple LR/SC pairs in sequence
    $display("\n--- Test 6: Multiple LR/SC Operations ---");
    write_data(10'h80, 32'h00000000, 0);

    // Perform 3 consecutive atomic increments
    for (int i = 0; i < 3; i++) begin
      logic success;
      atomic_increment(10'h80, 0, success);
      if (!success) begin
        $display("ERROR: Atomic increment %0d failed unexpectedly", i);
        test_passed = 1'b0;
      end
    end

    // Verify final value
    perform_read(10'h80, 0, read_data);
    if (read_data !== 32'h00000003) begin
      $display("ERROR: Multiple atomic increments failed. Expected: 0x%h, Got: 0x%h", 32'h00000003,
               read_data);
      test_passed = 1'b0;
    end

    // Final test summary
    $display("\n------------------------ TEST SUMMARY ------------------------");
    if (test_passed) $display("ALL TESTS PASSED SUCCESSFULLY");
    else $display("SOME TESTS FAILED - CHECK LOG FOR DETAILS");

    $display("------------------------ TEST COMPLETE ------------------------\n");

    // Finish simulation
    repeat (10) @(posedge axi_aclk);
    // $finish;
  end

  // Optional: Monitor for protocol violations
  property valid_before_ready_aw;
    @(posedge axi_aclk) axi_awvalid |-> ##[0:$] (axi_awready || !axi_awvalid);
  endproperty

  property valid_before_ready_w;
    @(posedge axi_aclk) axi_wvalid |-> ##[0:$] (axi_wready || !axi_wvalid);
  endproperty

  property valid_before_ready_ar;
    @(posedge axi_aclk) axi_arvalid |-> ##[0:$] (axi_arready || !axi_arvalid);
  endproperty

  // Assert these properties
  assert property (valid_before_ready_aw)
  else $error("AW valid without ready deadlock detected");
  assert property (valid_before_ready_w)
  else $error("W valid without ready deadlock detected");
  assert property (valid_before_ready_ar)
  else $error("AR valid without ready deadlock detected");

  // Optional: Generate VCD file for waveform viewing
  initial begin
    $dumpfile("ram_axi_tb.vcd");
    $dumpvars(0, ram_axi_tb);
  end

endmodule
