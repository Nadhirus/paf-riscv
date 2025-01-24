module rom #(
  parameter DATA_WIDTH = 32,
  parameter ADDR_WIDTH = 10
) (
  input  logic [(ADDR_WIDTH-1):0] addr,
  input  logic                    clk,
  output logic [(DATA_WIDTH-1):0] rdata,
  output logic                    rdata_valid
);


`ifdef SIMULATION
  logic [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
  initial begin
    // initialisation de la ROM avec le fichier d'initialisation
    // $readmemh("C:/Users/Nadhir/Desktop/NoRISC Vivado sim/NoRISC.srcs/sim_1/imports/rom/rom_data.mem", rom);
    rom[0] = 32'h01906093;
    rom[1] = 32'h02c06113;
    rom[2] = 32'h000001b3;
    rom[3] = 32'h00117213;
    rom[4] = 32'h40115113;
    rom[5] = 32'h00020463;
    rom[6] = 32'h001181b3;
    rom[7] = 32'h00109093;
    rom[8] = 32'hfe0116e3;
    rom[9] = 32'h003000b3;
    rom[10] = 32'h0000006f;
  end
`else
  (* ram_init_file = "C:\Users\Nadhir\Desktop\Projects\paf-riscv\paf-riscv\rom\rom_data.mif" *) logic [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];
`endif


  always @(posedge clk) begin
    rdata <= rom[addr];
  end

  assign rdata_valid = 1'b1;

endmodule
