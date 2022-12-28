`ifndef ALUTYPE
localparam ADD = 6'b000_000;
localparam SUB = 6'b001_000;
localparam SLL = 6'b000_001;
localparam SLT = 6'b000_010;
localparam SLTU= 6'b000_011;
localparam XOR = 6'b000_100;
localparam SRL = 6'b000_101;
localparam SRA = 6'b001_101;
localparam OR  = 6'b000_110;
localparam AND = 6'b000_111;

// bitmanip
localparam ANDN= 6'b001_111;
localparam ORN = 6'b001_110;
localparam XNOR= 6'b001_100;

localparam CLZ   = 6'b 0_11_000;
localparam CTZ   = 6'b 0_11_001;
localparam CPOP  = 6'b 0_11_010;
localparam SEXTB = 6'b 0_11_100;
localparam SEXTH = 6'b 0_11_101;
localparam ORCB  = 6'b 0_10_111;
localparam REV8  = 6'b 0_11_011;
localparam CLMUL = 6'b 1_00_001;
localparam CLMULH= 6'b 1_00_011;
localparam CLMULR= 6'b 1_00_010;
localparam BCLR  = 6'b 1_01_001;
localparam BEXT  = 6'b 1_01_101;
localparam BINV  = 6'b 1_11_001;
localparam BSET  = 6'b 1_10_001;

`define ALUTYPE
`endif
