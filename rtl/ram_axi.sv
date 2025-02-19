module ram_axi #(
  parameter DATA_WIDTH      = 32,
  parameter ADDR_WIDTH      = 10,
  parameter NUM_CORES       = 1,
  parameter MASTER_ID_WIDTH = $clog2(NUM_CORES)
) (
  input logic axi_aclk,
  input logic axi_aresetn,

  // Write Address Channel
  input  logic [ADDR_WIDTH-1:0] axi_awaddr,
  input  logic [           2:0] axi_awprot,
  input  logic                  axi_awvalid,
  output logic                  axi_awready,

  // Write Data Channel
  input  logic [    DATA_WIDTH-1:0] axi_wdata,
  input  logic [(DATA_WIDTH/8)-1:0] axi_wstrb,
  input  logic                      axi_wvalid,
  output logic                      axi_wready,

  // Write Response Channel
  output logic [1:0] axi_bresp,
  output logic       axi_bvalid,
  input  logic       axi_bready,

  // Read Address Channel
  input  logic [ADDR_WIDTH-1:0] axi_araddr,
  input  logic [           2:0] axi_arprot,
  input  logic                  axi_arvalid,
  output logic                  axi_arready,

  // Read Data Channel
  output logic [DATA_WIDTH-1:0] axi_rdata,
  output logic [           1:0] axi_rresp,
  output logic                  axi_rvalid,
  input  logic                  axi_rready,

  //  0 = normal, 1 = load-reserve (LR), 2 = store-conditional (SC)
  input logic [                1:0] axi_exclusive_op,
  // Master identifier (Une reservation par coeur, on peut ajouter plus)
  input logic [MASTER_ID_WIDTH-1:0] axi_master_id      // [NUM_reservations:0]
);

  // Memory array
  reg [DATA_WIDTH-1:0] ram              [2**ADDR_WIDTH-1:0];

  // Reservation table for exclusive accesses
  reg                  reservation_valid[    NUM_CORES-1:0];
  reg [ADDR_WIDTH-1:0] reservation_addr [    NUM_CORES-1:0];

  // Flag to indicate store-conditional failure
  reg                  sc_fail_flag;

  // Internal signals for write and read channels
  reg [ADDR_WIDTH-1:0] write_address;
  reg                  write_enable;
  reg [ADDR_WIDTH-1:0] read_address;

  // ============================================================
  // WRITE CHANNEL (Address, Data and Response)
  // ============================================================
  always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
    if (!axi_aresetn) begin
      axi_awready  <= 1'b0;
      axi_wready   <= 1'b0;
      axi_bvalid   <= 1'b0;
      sc_fail_flag <= 1'b0;
      // Clear the reservation table
      for (int i = 0; i < NUM_CORES; i++) begin
        reservation_valid[i] <= 1'b0;
        reservation_addr[i]  <= {ADDR_WIDTH{1'b0}};
      end
    end else begin
      // --- Write Address Channel ---
      if (axi_awvalid && axi_awready) begin
        // For SC operations, check that the reservation is still valid.
        if (axi_exclusive_op == 2'b10) begin  // SC
          if (reservation_valid[axi_master_id] &&
              (reservation_addr[axi_master_id] == axi_awaddr)) begin
            // Reservation is good; allow the SC write and clear the reservation.
            reservation_valid[axi_master_id] <= 1'b0;
            write_address <= axi_awaddr;
          end else begin
            // Reservation failed; mark flag so the write data will be ignored.
            sc_fail_flag  <= 1'b1;
            write_address <= axi_awaddr;  // capture the address 
          end
        end else begin
          // Normal write:
          // Invalidate any reservation matching this address (depuis n'import quel coeur)
          for (int i = 0; i < NUM_CORES; i++) begin
            if (reservation_valid[i] && (reservation_addr[i] == axi_awaddr))
              reservation_valid[i] <= 1'b0;
          end
          write_address <= axi_awaddr;
        end
        axi_awready <= 1'b0;
      end else begin
        // Ready whenever we are not busy issuing a write response.
        axi_awready <= ~axi_bvalid;
      end

      // --- Write Data Channel ---
      if (axi_wvalid && axi_wready) begin
        // Only write if not a SC failure.
        if (!sc_fail_flag) write_enable <= 1'b1;
        else write_enable <= 1'b0;
        axi_wready <= 1'b0;
      end else begin
        axi_wready   <= ~axi_bvalid;
        write_enable <= 1'b0;
      end

      // --- Write Response Channel ---
      if ((axi_awvalid && axi_wvalid && axi_awready && axi_wready) ||
          (axi_bvalid && axi_bready)) begin
        axi_bvalid <= 1'b1;
      end else if (axi_bvalid && axi_bready) begin
        axi_bvalid   <= 1'b0;
        // Clear SC failure flag after the response is sent.
        sc_fail_flag <= 1'b0;
      end
    end
  end

  // Set the write response: use an error code if SC failed.
  always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
    if (!axi_aresetn) begin
      axi_bresp <= 2'b00;
    end else begin
      if (axi_bvalid) begin
        if (sc_fail_flag)
          axi_bresp <= 2'b10;  // SC failure response
        else axi_bresp <= 2'b00;  // OKAY
      end
    end
  end

  // --- Memory Write Operation ---
  always_ff @(posedge axi_aclk) begin
    if (write_enable) begin
      for (int i = 0; i < (DATA_WIDTH / 8); i++) begin
        if (axi_wstrb[i]) begin
          ram[write_address][i*8+:8] <= axi_wdata[i*8+:8];
        end
      end
    end
  end

  // ============================================================
  // READ CHANNEL (Address, Data and Response)
  // ============================================================
  always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
    if (!axi_aresetn) begin
      axi_arready <= 1'b1;
      axi_rvalid  <= 1'b0;
    end else begin
      if (axi_arvalid && axi_arready) begin
        read_address <= axi_araddr;
        axi_arready  <= 1'b0;
        axi_rvalid   <= 1'b1;
        // If this is a LR access, record the reservation for this master.
        if (axi_exclusive_op == 2'b01) begin
          reservation_valid[axi_master_id] <= 1'b1;
          reservation_addr[axi_master_id]  <= axi_araddr;
        end
      end else if (axi_rvalid && axi_rready) begin
        axi_rvalid  <= 1'b0;
        axi_arready <= 1'b1;
      end
    end
  end

  // --- Memory Read Operation ---
  always_ff @(posedge axi_aclk) begin
    if (axi_arvalid && axi_arready) begin
      axi_rdata <= ram[axi_araddr];
    end
  end

  // Read response is always asserted.
  assign axi_rresp = 2'b00;

endmodule
