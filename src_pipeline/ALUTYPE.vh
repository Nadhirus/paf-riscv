localparam ADD = 6'b 000_000;
localparam SUB = 6'b 001_000;
localparam SLL = 6'b 000_001;
localparam SLT = 6'b 000_010;
localparam SLTU= 6'b 000_011;
localparam XOR = 6'b 000_100;
localparam SRL = 6'b 000_101;
localparam SRA = 6'b 001_101;
localparam OR  = 6'b 000_110;
localparam AND = 6'b 000_111;

// bitmanip
localparam ANDN= 6'b 001_111;
localparam ORN = 6'b 001_110;
localparam XNOR= 6'b 001_100;
localparam MIN = 6'b 001_010;
localparam MINU= 6'b 001_011;
localparam MAX = 6'b 011_110;
localparam MAXU= 6'b 011_111;
localparam ROR = 6'b 101_100;
localparam ROL = 6'b 101_110;

localparam CLZ   = 6'b 011_000;
localparam CTZ   = 6'b 011_001;
localparam CPOP  = 6'b 011_010;
localparam SEXTB = 6'b 011_100;
localparam SEXTH = 6'b 011_101;
localparam ZEXTH = 6'b 111_101;
localparam ORCB  = 6'b 010_111;
localparam REV8  = 6'b 011_011;
localparam CLMUL = 6'b 100_001;
localparam CLMULH= 6'b 100_011;
localparam CLMULR= 6'b 100_010;
localparam BCLR  = 6'b 101_001;
localparam BEXT  = 6'b 101_101;
localparam BINV  = 6'b 111_001;
localparam BSET  = 6'b 110_001;
