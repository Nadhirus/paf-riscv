  module DE1_SoC
    #(parameter ROM_ADDR_WIDTH=10, parameter RAM_ADDR_WIDTH=10)
    (
     ///////// clock /////////
     input logic 	clock_50,

     ///////// hex  /////////
     output logic [6:0] hex0,
     output logic [6:0] hex1,
     output logic [6:0] hex2,
     output logic [6:0] hex3,
     output logic [6:0] hex4,
     output logic [6:0] hex5,

     ///////// key /////////
     input logic [3:0] 	key,

     ///////// ledr /////////
     output logic [9:0] ledr,

     ///////// sw /////////
     input logic [9:0] 	sw,

     ///////// VGA  /////////
     output logic 	VGA_CLK,
     output logic 	VGA_HS,
     output logic 	VGA_VS,
     output logic 	VGA_BLANK,
     output logic [7:0] VGA_R,
     output logic [7:0] VGA_G,
     output logic [7:0] VGA_B,
     output logic 	VGA_SYNC

     );


   // Génération d'un reset à partir du bouton key[0]
   logic 			    reset_n;
   gene_reset gene_reset(.clk(clock_50), .key(key[0]), .reset_n(reset_n));

   // Instantication de la RAM pour les données
   logic [31:0] 		    ram_addr;
   logic [31:0] 		    ram_rdata, ram_wdata;
   logic 			    ram_we;
   logic 			    ram_rdata_valid;

   ram #(.ADDR_WIDTH(RAM_ADDR_WIDTH)) ram_data
     (
      .clk         ( clock_50                         ),
      .addr        ( ram_addr[(RAM_ADDR_WIDTH-1)+2:2] ),
      .we          ( ram_we                           ),
      .wdata       ( ram_wdata                        ),
      .rdata       ( ram_rdata                        ),
      .rdata_valid ( ram_rdata_valid                  )
      );

   // Instantication de la ROM pour les instructions
   logic [31:0] 		    rom_addr;
   logic [31:0] 		    rom_rdata;
   logic 			    rom_rdata_valid;

   rom #(.ADDR_WIDTH(ROM_ADDR_WIDTH)) rom_instructions
     (
      .clk         ( clock_50                         ),
      .addr        ( rom_addr[(ROM_ADDR_WIDTH-1)+2:2] ),
      .rdata       ( rom_rdata                        ),
      .rdata_valid ( rom_rdata_valid                  )
      );



   // @todo add write strobe support to ram.sv 
   wire [3:0] ram_wstrb;


   // Instanciation du processeur
   RISC risc
     (
      .clk            ( clock_50        ),
      .reset_n        ( reset_n         ),
      .d_address      ( ram_addr        ),
      .d_data_read    ( ram_rdata       ),
      .d_data_write   ( ram_wdata       ),
      .d_write_enable ( ram_we          ),
      .d_data_valid   ( ram_rdata_valid ),
      .d_data_wstrb   ( ram_wstrb       ),
      .i_address      ( rom_addr        ),
      .i_data_read    ( rom_rdata       ),
      .i_data_valid   ( rom_rdata_valid )
      );


  // set outputs in function of the processor state
  // so that quartus does not optimize the whole 
  // system out
    always@(posedge clock_50 or negedge reset_n)
      if(!reset_n)
        ledr <= '0;
      else begin
        ledr[0] <= ^ram_addr;
        ledr[1] <= ^ram_rdata;
        ledr[2] <= ^ram_wdata;
        ledr[3] <= ram_we;
        ledr[4] <= ram_rdata_valid;
        ledr[5] <= ^ram_wstrb;
        ledr[6] <= ^rom_addr;
        ledr[7] <= ^rom_rdata;
        ledr[8] <= rom_rdata_valid;
      end

endmodule
