module ram_axi #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 10
) (
  // AXI4-Lite Interface
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
  input  logic                  axi_rready
);

  // Memory array
  reg   [DATA_WIDTH-1:0] ram           [2**ADDR_WIDTH-1:0];

  // Internal signals
  logic [ADDR_WIDTH-1:0] write_address;
  logic [ADDR_WIDTH-1:0] read_address;
  logic                  write_enable;

  // Write handling
  always_ff @(posedge axi_aclk) begin
    if (!axi_aresetn) begin
      axi_awready <= 1'b0;
      axi_wready  <= 1'b0;
      axi_bvalid  <= 1'b0;
    end else begin
      // Write address channel
      if (axi_awvalid && axi_awready) begin
        write_address <= axi_awaddr;
        axi_awready   <= 1'b0;
      end else begin
        axi_awready <= ~axi_bvalid && ~axi_awready;
      end

      // Write data channel
      if (axi_wvalid && axi_wready) begin
        write_enable <= 1'b1;
        axi_wready   <= 1'b0;
      end else begin
        axi_wready   <= ~axi_bvalid && ~axi_wready;
        write_enable <= 1'b0;
      end

      // Write response
      if (axi_awvalid && axi_wvalid && axi_awready && axi_wready) begin
        axi_bvalid <= 1'b1;
      end else if (axi_bready && axi_bvalid) begin
        axi_bvalid <= 1'b0;
      end
    end
  end

  // Memory write operation
  always_ff @(posedge axi_aclk) begin
    if (write_enable) begin
      for (int i = 0; i < (DATA_WIDTH / 8); i++) begin
        if (axi_wstrb[i]) begin
          ram[write_address][i*8+:8] <= axi_wdata[i*8+:8];
        end
      end
    end
  end

  // Read handling
  always_ff @(posedge axi_aclk) begin
    if (!axi_aresetn) begin
      axi_arready <= 1'b1;
      axi_rvalid  <= 1'b0;
    end else begin
      // Read address channel
      if (axi_arvalid && axi_arready) begin
        read_address <= axi_araddr;
        axi_arready  <= 1'b0;
        axi_rvalid   <= 1'b1;
      end else if (axi_rvalid && axi_rready) begin
        axi_rvalid  <= 1'b0;
        axi_arready <= 1'b1;
      end
    end
  end

  // Memory read operation
  always_ff @(posedge axi_aclk) begin
    if (axi_arvalid && axi_arready) begin
      axi_rdata <= ram[axi_araddr];
    end
  end

  // Response signals
  assign axi_bresp = 2'b00;  // OKAY
  assign axi_rresp = 2'b00;  // OKAY

  // // Initialize memory from file
  // initial begin
  //   $readmemh("ram_init.mem", ram);
  // end
endmodule
