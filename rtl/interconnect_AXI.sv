module axi_interconnect #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32,
  parameter ID_WIDTH = 4,
  parameter NUM_MASTERS = 2,
  parameter NUM_SLAVES = 3,
  parameter [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] SLAVE_BASE_ADDR = {
    32'h2000_0000,  // Slave 2 base address
    32'h1000_0000,  // Slave 1 base address
    32'h0000_0000   // Slave 0 base address
  },
  parameter [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] SLAVE_ADDR_MASK = {
    32'hF000_0000,  // Slave 2 address mask
    32'hF000_0000,  // Slave 1 address mask
    32'hF000_0000   // Slave 0 address mask
  }
) (
  input  wire                           clk,
  input  wire                           rst_n,

  // Master Interface Ports
  // Write Address Channel
  input  wire [NUM_MASTERS-1:0][ID_WIDTH-1:0]   m_axi_awid,
  input  wire [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]   m_axi_awaddr,
  input  wire [NUM_MASTERS-1:0][2:0]              m_axi_awprot,
  input  wire [NUM_MASTERS-1:0]                   m_axi_awvalid,
  input  wire [NUM_MASTERS-1:0]                   m_axi_awlock,
  output logic [NUM_MASTERS-1:0]                  m_axi_awready,

  // Write Data Channel
  input  wire [NUM_MASTERS-1:0][DATA_WIDTH-1:0]   m_axi_wdata,
  input  wire [NUM_MASTERS-1:0][(DATA_WIDTH/8)-1:0] m_axi_wstrb,
  input  wire [NUM_MASTERS-1:0]                   m_axi_wvalid,
  output logic [NUM_MASTERS-1:0]                  m_axi_wready,

  // Write Response Channel
  output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0]    m_axi_bid,
  output logic [NUM_MASTERS-1:0][1:0]             m_axi_bresp,
  output logic [NUM_MASTERS-1:0]                  m_axi_bvalid,
  input  wire [NUM_MASTERS-1:0]                   m_axi_bready,

  // Read Address Channel
  input  wire [NUM_MASTERS-1:0][ID_WIDTH-1:0]     m_axi_arid,
  input  wire [NUM_MASTERS-1:0][ADDR_WIDTH-1:0]     m_axi_araddr,
  input  wire [NUM_MASTERS-1:0][2:0]                m_axi_arprot,
  input  wire [NUM_MASTERS-1:0]                   m_axi_arvalid,
  input  wire [NUM_MASTERS-1:0]                   m_axi_arlock,
  output logic [NUM_MASTERS-1:0]                  m_axi_arready,

  // Read Data Channel
  output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0]    m_axi_rid,
  output logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0]  m_axi_rdata,
  output logic [NUM_MASTERS-1:0][1:0]             m_axi_rresp,
  output logic [NUM_MASTERS-1:0]                  m_axi_rvalid,
  input  wire [NUM_MASTERS-1:0]                   m_axi_rready,

  // Slave Interface Ports
  // Write Address Channel
  output logic [NUM_SLAVES-1:0][ID_WIDTH-1:0]     s_axi_awid,
  output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0]     s_axi_awaddr,
  output logic [NUM_SLAVES-1:0][2:0]                s_axi_awprot,
  output logic [NUM_SLAVES-1:0]                   s_axi_awvalid,
  output logic [NUM_SLAVES-1:0]                   s_axi_awlock,
  input  wire [NUM_SLAVES-1:0]                   s_axi_awready,

  // Write Data Channel
  output logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0]   s_axi_wdata,
  output logic [NUM_SLAVES-1:0][(DATA_WIDTH/8)-1:0] s_axi_wstrb,
  output logic [NUM_SLAVES-1:0]                   s_axi_wvalid,
  input  wire [NUM_SLAVES-1:0]                   s_axi_wready,

  // Write Response Channel
  input  wire [NUM_SLAVES-1:0][ID_WIDTH-1:0]      s_axi_bid,
  input  wire [NUM_SLAVES-1:0][1:0]               s_axi_bresp,
  input  wire [NUM_SLAVES-1:0]                   s_axi_bvalid,
  output logic [NUM_SLAVES-1:0]                   s_axi_bready,

  // Read Address Channel
  output logic [NUM_SLAVES-1:0][ID_WIDTH-1:0]     s_axi_arid,
  output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0]     s_axi_araddr,
  output logic [NUM_SLAVES-1:0][2:0]                s_axi_arprot,
  output logic [NUM_SLAVES-1:0]                   s_axi_arvalid,
  output logic [NUM_SLAVES-1:0]                   s_axi_arlock,
  input  wire [NUM_SLAVES-1:0]                   s_axi_arready,

  // Read Data Channel
  input  wire [NUM_SLAVES-1:0][ID_WIDTH-1:0]      s_axi_rid,
  input  wire [NUM_SLAVES-1:0][DATA_WIDTH-1:0]    s_axi_rdata,
  input  wire [NUM_SLAVES-1:0][1:0]               s_axi_rresp,
  input  wire [NUM_SLAVES-1:0]                   s_axi_rvalid,
  output logic [NUM_SLAVES-1:0]                   s_axi_rready
);

  // Internal signals for arbitration
  logic [NUM_MASTERS-1:0] aw_request;
  logic [NUM_MASTERS-1:0] aw_grant;
  logic [NUM_MASTERS-1:0] ar_request;
  logic [NUM_MASTERS-1:0] ar_grant;

  // Slave select signals
  logic [NUM_SLAVES-1:0] aw_slave_sel;
  logic [NUM_SLAVES-1:0] ar_slave_sel;

  // Current master indices for read and write channels
  logic [$clog2(NUM_MASTERS)-1:0] current_write_master;
  logic [$clog2(NUM_MASTERS)-1:0] current_read_master;

  // Current slave indices for read and write channels
  logic [$clog2(NUM_SLAVES)-1:0] current_write_slave;
  logic [$clog2(NUM_SLAVES)-1:0] current_read_slave;

  // Transaction tracking
  enum logic [1:0] {
    IDLE,
    ADDR,
    DATA,
    RESP
  } write_state, read_state;

  // Simple round-robin arbitration priority registers
  logic [$clog2(NUM_MASTERS)-1:0] write_priority, read_priority;

  // Function to determine which slave an address maps to
  function automatic logic [NUM_SLAVES-1:0] get_slave_select(input logic [ADDR_WIDTH-1:0] addr);
    logic [NUM_SLAVES-1:0] select;
    for (int i = 0; i < NUM_SLAVES; i++) begin
      select[i] = ((addr & SLAVE_ADDR_MASK[i]) == SLAVE_BASE_ADDR[i]);
    end
    return select;
  endfunction

  // Round-robin arbitration for write address channel
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_priority       <= '0;
      write_state          <= IDLE;
      current_write_master <= '0;
      current_write_slave  <= '0;
      aw_grant             <= '0;
    end else begin
      case (write_state)
        IDLE: begin
          // Detect write requests
          for (int i = 0; i < NUM_MASTERS; i++) begin
            aw_request[i] = m_axi_awvalid[i];
          end

          // Grant access based on round-robin priority starting from write_priority
          aw_grant <= '0;
          for (int i = 0; i < NUM_MASTERS; i++) begin
            automatic int idx = (write_priority + i) % NUM_MASTERS;
            if (aw_request[idx] && !aw_grant) begin
              aw_grant[idx] <= 1'b1;
              current_write_master <= idx;

              // Determine target slave
              aw_slave_sel = get_slave_select(m_axi_awaddr[idx]);

              // Find the first matching slave
              current_write_slave <= '0;
              for (int j = 0; j < NUM_SLAVES; j++) begin
                if (aw_slave_sel[j]) begin
                  current_write_slave <= j;
                  break;
                end
              end

              // Advance state
              write_state <= ADDR;
            end
          end
        end

        ADDR: begin
          // Address phase
          if (s_axi_awready[current_write_slave]) begin
            write_state <= DATA;
          end
        end

        DATA: begin
          // Data phase
          if (s_axi_wready[current_write_slave] && m_axi_wvalid[current_write_master]) begin
            write_state <= RESP;
          end
        end

        RESP: begin
          // Response phase
          if (s_axi_bvalid[current_write_slave] && m_axi_bready[current_write_master]) begin
            write_state <= IDLE;
            aw_grant <= '0;
            // Update priority for next round
            write_priority <= (current_write_master + 1) % NUM_MASTERS;
          end
        end
      endcase
    end
  end

  // Round-robin arbitration for read address channel
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_priority       <= '0;
      read_state          <= IDLE;
      current_read_master <= '0;
      current_read_slave  <= '0;
      ar_grant            <= '0;
    end else begin
      case (read_state)
        IDLE: begin
          // Detect read requests
          for (int i = 0; i < NUM_MASTERS; i++) begin
            ar_request[i] = m_axi_arvalid[i];
          end

          // Grant access based on round-robin priority starting from read_priority
          ar_grant <= '0;
          for (int i = 0; i < NUM_MASTERS; i++) begin
            automatic int idx = (read_priority + i) % NUM_MASTERS;
            if (ar_request[idx] && !ar_grant) begin
              ar_grant[idx] <= 1'b1;
              current_read_master <= idx;

              // Determine target slave
              ar_slave_sel = get_slave_select(m_axi_araddr[idx]);

              // Find the first matching slave
              current_read_slave <= '0;
              for (int j = 0; j < NUM_SLAVES; j++) begin
                if (ar_slave_sel[j]) begin
                  current_read_slave <= j;
                  break;
                end
              end

              // Advance state
              read_state <= ADDR;
            end
          end
        end

        ADDR: begin
          // Address phase
          if (s_axi_arready[current_read_slave]) begin
            read_state <= RESP;
          end
        end

        RESP: begin
          // Response phase
          if (s_axi_rvalid[current_read_slave] && m_axi_rready[current_read_master]) begin
            read_state <= IDLE;
            ar_grant <= '0;
            // Update priority for next round
            read_priority <= (current_read_master + 1) % NUM_MASTERS;
          end
        end

        default: read_state <= IDLE;
      endcase
    end
  end

  // Connect Master to Slave signals
  // Write Address Channel
  always_comb begin
    if (!rst_n) begin
      // Force outputs to reset values
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_awready[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_awid[j]    = '0;
        s_axi_awaddr[j]  = '0;
        s_axi_awprot[j]  = '0;
        s_axi_awvalid[j] = 1'b0;
        s_axi_awlock[j]  = 1'b0;
      end
    end else begin
      // Default assignments
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_awready[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_awid[j]    = '0;
        s_axi_awaddr[j]  = '0;
        s_axi_awprot[j]  = '0;
        s_axi_awvalid[j] = 1'b0;
        s_axi_awlock[j]  = 1'b0;
      end

      // Active connections based on arbitration
      if (write_state == ADDR) begin
        m_axi_awready[current_write_master] = s_axi_awready[current_write_slave];
        s_axi_awid[current_write_slave]     = m_axi_awid[current_write_master];
        s_axi_awaddr[current_write_slave]   = m_axi_awaddr[current_write_master];
        s_axi_awprot[current_write_slave]   = m_axi_awprot[current_write_master];
        s_axi_awvalid[current_write_slave]  = m_axi_awvalid[current_write_master];
        s_axi_awlock[current_write_slave]   = m_axi_awlock[current_write_master];
      end
    end
  end

  // Write Data Channel
  always_comb begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_wready[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_wdata[j]  = '0;
        s_axi_wstrb[j]  = '0;
        s_axi_wvalid[j] = 1'b0;
      end
    end else begin
      // Default assignments
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_wready[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_wdata[j]  = '0;
        s_axi_wstrb[j]  = '0;
        s_axi_wvalid[j] = 1'b0;
      end

      // Active connections based on arbitration
      if (write_state == DATA) begin
        m_axi_wready[current_write_master] = s_axi_wready[current_write_slave];
        s_axi_wdata[current_write_slave]   = m_axi_wdata[current_write_master];
        s_axi_wstrb[current_write_slave]   = m_axi_wstrb[current_write_master];
        s_axi_wvalid[current_write_slave]  = m_axi_wvalid[current_write_master];
      end
    end
  end

  // Write Response Channel
  always_comb begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_bid[i]   = '0;
        m_axi_bresp[i] = '0;
        m_axi_bvalid[i]= 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_bready[j] = 1'b0;
      end
    end else begin
      // Default assignments
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_bid[i]   = '0;
        m_axi_bresp[i] = '0;
        m_axi_bvalid[i]= 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_bready[j] = 1'b0;
      end

      // Active connections based on arbitration
      if (write_state == RESP) begin
        m_axi_bid[current_write_master]   = s_axi_bid[current_write_slave];
        m_axi_bresp[current_write_master] = s_axi_bresp[current_write_slave];
        m_axi_bvalid[current_write_master]= s_axi_bvalid[current_write_slave];
        s_axi_bready[current_write_slave] = m_axi_bready[current_write_master];
      end
    end
  end

  // Read Address Channel
  always_comb begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_arready[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_arid[j]    = '0;
        s_axi_araddr[j]  = '0;
        s_axi_arprot[j]  = '0;
        s_axi_arvalid[j] = 1'b0;
        s_axi_arlock[j]  = 1'b0;
      end
    end else begin
      // Default assignments
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_arready[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_arid[j]    = '0;
        s_axi_araddr[j]  = '0;
        s_axi_arprot[j]  = '0;
        s_axi_arvalid[j] = 1'b0;
        s_axi_arlock[j]  = 1'b0;
      end

      // Active connections based on arbitration
      if (read_state == ADDR) begin
        m_axi_arready[current_read_master] = s_axi_arready[current_read_slave];
        s_axi_arid[current_read_slave]     = m_axi_arid[current_read_master];
        s_axi_araddr[current_read_slave]   = m_axi_araddr[current_read_master];
        s_axi_arprot[current_read_slave]   = m_axi_arprot[current_read_master];
        s_axi_arvalid[current_read_slave]  = m_axi_arvalid[current_read_master];
        s_axi_arlock[current_read_slave]   = m_axi_arlock[current_read_master];
      end
    end
  end

  // Read Data Channel
  always_comb begin
    if (!rst_n) begin
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_rid[i]    = '0;
        m_axi_rdata[i]  = '0;
        m_axi_rresp[i]  = '0;
        m_axi_rvalid[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_rready[j] = 1'b0;
      end
    end else begin
      // Default assignments
      for (int i = 0; i < NUM_MASTERS; i++) begin
        m_axi_rid[i]    = '0;
        m_axi_rdata[i]  = '0;
        m_axi_rresp[i]  = '0;
        m_axi_rvalid[i] = 1'b0;
      end
      for (int j = 0; j < NUM_SLAVES; j++) begin
        s_axi_rready[j] = 1'b0;
      end

      // Active connections based on arbitration
      if (read_state == RESP) begin
        m_axi_rid[current_read_master]    = s_axi_rid[current_read_slave];
        m_axi_rdata[current_read_master]  = s_axi_rdata[current_read_slave];
        m_axi_rresp[current_read_master]  = s_axi_rresp[current_read_slave];
        m_axi_rvalid[current_read_master] = s_axi_rvalid[current_read_slave];
        s_axi_rready[current_read_slave]  = m_axi_rready[current_read_master];
      end
    end
  end

endmodule
