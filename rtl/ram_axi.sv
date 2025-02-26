module ram_axi #(
  parameter DATA_WIDTH      = 32,
  parameter ADDR_WIDTH      = 10,
  parameter NUM_CORES       = 1,
  parameter MASTER_ID_WIDTH = $clog2(NUM_CORES)
) (
  input logic axi_aclk,
  input logic axi_aresetn,

  // Write Address Channel
  input  logic [     ADDR_WIDTH-1:0] axi_awaddr,
  input  logic [                2:0] axi_awprot,
  input  logic                       axi_awvalid,
  output logic                       axi_awready,
  // Exclusive access signals for write
  input  logic [MASTER_ID_WIDTH-1:0] axi_awid,
  input  logic                       axi_awlock,

  // Write Data Channel
  input  logic [    DATA_WIDTH-1:0] axi_wdata,
  input  logic [(DATA_WIDTH/8)-1:0] axi_wstrb,
  input  logic                      axi_wvalid,
  output logic                      axi_wready,

  // Write Response Channel
  output logic [                1:0] axi_bresp,
  output logic                       axi_bvalid,
  input  logic                       axi_bready,
  output logic [MASTER_ID_WIDTH-1:0] axi_bid,

  // Read Address Channel
  input  logic [ADDR_WIDTH-1:0] axi_araddr,
  input  logic [           2:0] axi_arprot,
  input  logic                  axi_arvalid,
  output logic                  axi_arready,

  // Exclusive access signals for read
  input logic [MASTER_ID_WIDTH-1:0] axi_arid,
  input logic                       axi_arlock,

  // Read Data Channel
  output logic [     DATA_WIDTH-1:0] axi_rdata,
  output logic [                1:0] axi_rresp,
  output logic                       axi_rvalid,
  input  logic                       axi_rready,
  output logic [MASTER_ID_WIDTH-1:0] axi_rid,

  // Atomic operation lock control (one bit per core)
  input logic [NUM_CORES-1:0] axi_core_block
);

  // Memory array
  reg  [     DATA_WIDTH-1:0] ram                                          [0:(2**ADDR_WIDTH)-1];

  // Reservation table for exclusive accesses
  reg                        reservation_valid                            [      0:NUM_CORES-1];
  reg  [     ADDR_WIDTH-1:0] reservation_addr                             [      0:NUM_CORES-1];

  // Internal signals for write channel
  reg  [     ADDR_WIDTH-1:0] write_address;
  reg                        exclusive_write_fail;
  reg  [MASTER_ID_WIDTH-1:0] current_write_id;
  reg                        write_addr_valid;
  reg                        write_data_valid;
  reg                        current_awlock;  // Latch for the lock signal

  // Internal signals for read channel
  reg  [     ADDR_WIDTH-1:0] read_address;
  reg  [MASTER_ID_WIDTH-1:0] current_read_id;
  reg                        read_addr_valid;

  // Blocking control signals
  wire                       core_is_blocked_r;
  wire                       core_is_blocked_w;

  assign core_is_blocked_r = |(axi_core_block & ~(1 << axi_arid));
  assign core_is_blocked_w = |(axi_core_block & ~(1 << axi_awid));

  // ----------------------------------------------------------------
  // WRITE CHANNEL: Address, Data, and Response Handling
  // ----------------------------------------------------------------
  always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
    if (!axi_aresetn) begin
      axi_awready          <= 1'b1;
      axi_wready           <= 1'b1;
      axi_bvalid           <= 1'b0;
      axi_bid              <= '0;
      exclusive_write_fail <= 1'b0;
      write_addr_valid     <= 1'b0;
      write_data_valid     <= 1'b0;
      current_awlock       <= 1'b0;
      // Clear reservation table
      for (int i = 0; i < NUM_CORES; i++) begin
        reservation_valid[i] <= 1'b0;
        reservation_addr[i]  <= '0;
      end
    end else begin
      // Write Address Channel
      if (axi_awready && axi_awvalid && !core_is_blocked_w) begin
        write_addr_valid <= 1'b1;
        write_address    <= axi_awaddr;
        current_write_id <= axi_awid;
        current_awlock   <= axi_awlock;  // Latch the lock signal

        // Check for exclusive access
        if (axi_awlock) begin
          // Check if reservation is valid and matches address
          if (reservation_valid[axi_awid] && (reservation_addr[axi_awid] == axi_awaddr)) begin
            exclusive_write_fail <= 1'b0;
            reservation_valid[axi_awid] <= 1'b0;  // Clear reservation after use
          end else begin
            exclusive_write_fail <= 1'b1;
          end
        end else begin
          // Normal write: Invalidate any matching reservation
          for (int i = 0; i < NUM_CORES; i++) begin
            if (reservation_valid[i] && (reservation_addr[i] == axi_awaddr))
              reservation_valid[i] <= 1'b0;
          end
          exclusive_write_fail <= 1'b0;
        end
        axi_awready <= 1'b0;
      end else if (!write_addr_valid) begin
        axi_awready <= !core_is_blocked_w;
      end

      // Write Data Channel
      if (axi_wready && axi_wvalid && !core_is_blocked_w) begin
        write_data_valid <= 1'b1;
        axi_wready <= 1'b0;
      end else if (!write_data_valid) begin
        axi_wready <= (!axi_bvalid && !core_is_blocked_w);
      end

      // When both address and data have been received, perform write and issue response.
      if (write_addr_valid && write_data_valid) begin
        if (!current_awlock || !exclusive_write_fail) begin
          // Write data into memory using byte enables.
          for (int i = 0; i < (DATA_WIDTH / 8); i++) begin
            if (axi_wstrb[i]) ram[write_address][i*8+:8] <= axi_wdata[i*8+:8];
          end
        end
        axi_bvalid <= 1'b1;
        axi_bid    <= current_write_id;
        // Clear handshake flags for next transaction.
        write_addr_valid <= 1'b0;
        write_data_valid <= 1'b0;
      end

      // Write Response handshake
      if (axi_bvalid && axi_bready) begin
        axi_bvalid <= 1'b0;
        exclusive_write_fail <= 1'b0;
        axi_awready <= !core_is_blocked_w;
        axi_wready <= !core_is_blocked_w;
      end
    end
  end

  // Write Response Code Generation
  always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
    if (!axi_aresetn) begin
      axi_bresp <= 2'b00;
    end else if (write_addr_valid && write_data_valid) begin
      if (core_is_blocked_w) axi_bresp <= 2'b10;  // Blocked access (SLVERR)
      else if (current_awlock) begin
        if (exclusive_write_fail) axi_bresp <= 2'b10;  // Exclusive access failure (SLVERR)
        else axi_bresp <= 2'b01;  // Successful exclusive access (EXOKAY)
      end else begin
        axi_bresp <= 2'b00;  // Normal write (OKAY)
      end
    end
  end

  // ----------------------------------------------------------------
  // READ CHANNEL: Address and Data Handling
  // ----------------------------------------------------------------
  always_ff @(posedge axi_aclk or negedge axi_aresetn) begin
    if (!axi_aresetn) begin
      axi_arready     <= 1'b1;
      axi_rvalid      <= 1'b0;
      axi_rid         <= '0;
      read_addr_valid <= 1'b0;
      axi_rresp       <= 2'b00;
      axi_rdata       <= '0;
    end else begin
      if (axi_arready && axi_arvalid && !core_is_blocked_r) begin
        read_addr_valid <= 1'b1;
        read_address    <= axi_araddr;
        current_read_id <= axi_arid;
        axi_arready     <= 1'b0;
        axi_rvalid      <= 1'b1;
        axi_rid         <= axi_arid;

        // Read data from memory
        axi_rdata       <= ram[axi_araddr];

        // For exclusive read, set a reservation
        if (axi_arlock) begin
          reservation_valid[axi_arid] <= 1'b1;
          reservation_addr[axi_arid] <= axi_araddr;
          axi_rresp <= 2'b01;  // EXOKAY for exclusive read
        end else begin
          axi_rresp <= 2'b00;  // OKAY for normal read

        end
      end else if (axi_rvalid && axi_rready) begin
        axi_rvalid      <= 1'b0;
        read_addr_valid <= 1'b0;
        axi_arready     <= !core_is_blocked_r;
      end else if (!axi_rvalid) begin
        axi_arready <= !core_is_blocked_r;
      end
    end
  end

endmodule
