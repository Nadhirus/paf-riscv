`timescale 1ns/1ps

module ram_axi_tb;

  // Parameters
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 10;
  localparam NUM_CORES = 2;  // Using 2 cores for testing
  localparam MASTER_ID_WIDTH = $clog2(NUM_CORES);

  // Clock and reset
  logic axi_aclk;
  logic axi_aresetn;

  // Write Address Channel
  logic [ADDR_WIDTH-1:0] axi_awaddr;
  logic [2:0] axi_awprot;
  logic axi_awvalid;
  logic axi_awready;
  logic [MASTER_ID_WIDTH-1:0] axi_awid;
  logic axi_awlock;

  // Write Data Channel
  logic [DATA_WIDTH-1:0] axi_wdata;
  logic [(DATA_WIDTH/8)-1:0] axi_wstrb;
  logic axi_wvalid;
  logic axi_wready;

  // Write Response Channel
  logic [1:0] axi_bresp;
  logic axi_bvalid;
  logic axi_bready;
  logic [MASTER_ID_WIDTH-1:0] axi_bid;

  // Read Address Channel
  logic [ADDR_WIDTH-1:0] axi_araddr;
  logic [2:0] axi_arprot;
  logic axi_arvalid;
  logic axi_arready;
  logic [MASTER_ID_WIDTH-1:0] axi_arid;
  logic axi_arlock;

  // Read Data Channel
  logic [DATA_WIDTH-1:0] axi_rdata;
  logic [1:0] axi_rresp;
  logic axi_rvalid;
  logic axi_rready;
  logic [MASTER_ID_WIDTH-1:0] axi_rid;

  // Atomic operation lock control
  logic [NUM_CORES-1:0] axi_core_block;

  // Instantiate the RAM AXI module
  ram_axi #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .NUM_CORES(NUM_CORES),
    .MASTER_ID_WIDTH(MASTER_ID_WIDTH)
  ) dut (
    .axi_aclk(axi_aclk),
    .axi_aresetn(axi_aresetn),
    
    // Write Address Channel
    .axi_awaddr(axi_awaddr),
    .axi_awprot(axi_awprot),
    .axi_awvalid(axi_awvalid),
    .axi_awready(axi_awready),
    .axi_awid(axi_awid),
    .axi_awlock(axi_awlock),
    
    // Write Data Channel
    .axi_wdata(axi_wdata),
    .axi_wstrb(axi_wstrb),
    .axi_wvalid(axi_wvalid),
    .axi_wready(axi_wready),
    
    // Write Response Channel
    .axi_bresp(axi_bresp),
    .axi_bvalid(axi_bvalid),
    .axi_bready(axi_bready),
    .axi_bid(axi_bid),
    
    // Read Address Channel
    .axi_araddr(axi_araddr),
    .axi_arprot(axi_arprot),
    .axi_arvalid(axi_arvalid),
    .axi_arready(axi_arready),
    .axi_arid(axi_arid),
    .axi_arlock(axi_arlock),
    
    // Read Data Channel
    .axi_rdata(axi_rdata),
    .axi_rresp(axi_rresp),
    .axi_rvalid(axi_rvalid),
    .axi_rready(axi_rready),
    .axi_rid(axi_rid),
    
    // Atomic operation lock control
    .axi_core_block(axi_core_block)
  );

  initial begin
    axi_aclk = 0;
    forever #5 axi_aclk = ~axi_aclk;
  end

  // Initial reset
  initial begin
    axi_aresetn = 0;
    axi_awaddr = 0;
    axi_awprot = 0;
    axi_awvalid = 0;
    axi_awid = 0;
    axi_awlock = 0;
    axi_wdata = 0;
    axi_wstrb = 0;
    axi_wvalid = 0;
    axi_bready = 0;
    axi_araddr = 0;
    axi_arprot = 0;
    axi_arvalid = 0;
    axi_arid = 0;
    axi_arlock = 0;
    axi_rready = 0;
    axi_core_block = 0;

    #20 axi_aresetn = 1;
    
  end

	sequence lr_precedes_sc;
		axi_arvalid && axi_arlock ##[1:$] axi_awvalid && axi_awlock;
	endsequence

	sequence overlapping_atomic_access;
		(axi_awvalid && axi_awlock) ##1 (axi_awvalid && axi_awlock && (axi_awaddr == $past(axi_awaddr)));
	endsequence

	// une fois que axi_awlock est mis à  1, le bus doit etre locké jusqu'a ce qu'il soit pret(ready)
	property bus_lock_active;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  axi_awlock |-> ##1 (!axi_awready || axi_awlock);
	endproperty

	// Acces exclusif d'un coeur
	property exclusive_access;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  axi_awlock |-> (!($onehot(axi_awid)) || axi_awlock);
	endproperty

	// Pas d'overlap d'acces
	property no_overlapping_access;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  !$rose(axi_awlock) or !$rose(axi_awvalid) [*1:$] |-> ##1 (axi_awready || !axi_awlock);
	endproperty

	//Bon ordre de la sequence 
	property atomic_rmw_sequence;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  (axi_awlock && axi_awvalid) |=> (axi_wdata !== 'x) ##1 (axi_awready && axi_wvalid) |-> axi_bvalid;
	endproperty
	
	//Pas d'autre Transaction quand le bus est locké
	property no_interleaved_transactions;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  axi_awlock |-> ##1 (!$rose(axi_awvalid && axi_awid !== $past(axi_awid)));
	endproperty

	//Une fois la transaction terminé, on release le bus.
	property lock_release_after_completion;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  axi_awlock && axi_awvalid && axi_awready |=> ##1 !axi_awlock;
	endproperty

	//SC succès.
	property store_conditional_check;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  (axi_awlock && axi_awvalid) |-> ##[1:$] (axi_wvalid && axi_bvalid);
	endproperty
	
	//Deadlock càd bus locké trop longtemps car pas recu de ready: famine
	property no_deadlock;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  axi_awlock |-> ##[1:10] axi_awready;
	endproperty

	//SC apres un LR valide.
	property store_conditional_follows_lr;
		@(posedge axi_aclk) disable iff (!axi_aresetn)
		(axi_awlock && axi_awvalid) |-> $past(axi_arvalid && axi_arlock);
	endproperty

	//LR lit la bonne valeur.
	property lr_reads_correct_data;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  (axi_arvalid && axi_arlock) |-> ##1 (axi_rvalid && axi_rdata == $past(axi_wdata));
	endproperty

	//Si la reservation (càd le bit de reservation) echoue(a cause d'un autre access à la meme @
	property sc_fails_on_reservation_loss;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  (axi_awvalid && axi_awlock && axi_awready) |-> ##[1:$] (axi_bvalid || (axi_bresp == 2'b00));
	endproperty

	//L'@ doit etre aligné.
	property atomic_address_alignment;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  (axi_awvalid && axi_awlock) |-> (axi_awaddr[1:0] == 2'b00);
	endproperty

	//Access simultané à la meme @
	property no_simultaneous_atomic_accesses;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  not overlapping_atomic_access;
	endproperty

	//Reponse AXI est valide
	property axi_response_valid;
	  @(posedge axi_aclk) disable iff (!axi_aresetn)
	  axi_bvalid |-> (axi_bresp == 2'b00 || axi_bresp == 2'b10);
	endproperty



	assert property (bus_lock_active)
	else $error("Bus lock violation: axi_awready deasserted before lock is released");

	assert property (exclusive_access)
	else $error("Exclusive access violation: Multiple cores attempted locked transactions");

	assert property (no_overlapping_access)
	else $error("Overlapping locked transactions detected");
	
	assert property (atomic_rmw_sequence)
	else $error("Atomic RMW violation: Transaction sequence is incorrect.");
	
	assert property (no_interleaved_transactions)
	else $error("Interleaved transactions detected during a locked access.");

	assert property (lock_release_after_completion)
	else $error("Lock was not released after the transaction completed.");
	
	assert property (store_conditional_check)
	else $error("Store-Conditional failed unexpectedly.");
	  
	assert property (no_deadlock)
	else $error("Possible deadlock detected: lock held too long.");
	
	assert property (store_conditional_follows_lr)
	else $error("Store-Conditional issued without prior Load-Reserved.");
	
	assert property (lr_reads_correct_data)
	else $error("Load-Reserved read incorrect data.");
	
	assert property (sc_fails_on_reservation_loss)
	else $error("Store-Conditional succeeded despite reservation loss.");
	
	assert property (atomic_address_alignment)
	else $error("Atomic operation issued on misaligned address.");
	
	assert property (no_simultaneous_atomic_accesses)
	else $error("Two cores issued atomic transactions to the same address.");	
	
	assert property (axi_response_valid)
	else $error("Invalid AXI response received.");
	
endmodule