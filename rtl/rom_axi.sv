module rom_axi #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 10
) (
  // AXI4-Lite Interface
  input logic axi_aclk,
  input logic axi_aresetn,

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
  reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

  // Internal signals
  logic [ADDR_WIDTH-1:0] read_address;

  // Read handling
  always_ff @(posedge axi_aclk) begin
    if (!axi_aresetn) begin
      axi_arready <= 1'b1;
      axi_rvalid  <= 1'b0;
    end else begin
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
      axi_rdata <= rom[axi_araddr];
    end
  end

  assign axi_rresp = 2'b00;  // OKAY

  // Initialize memory from file
  initial begin
`ifdef SIMULATION
    $readmemh("rom_data.mem", rom);
`else
  // pour FPGA
  (* ram_init_file = "C:\Users\Nadhir\Desktop\Projects\paf-riscv\paf-riscv\rom\rom_data.mif" *) logic [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
`endif
  end

endmodule
