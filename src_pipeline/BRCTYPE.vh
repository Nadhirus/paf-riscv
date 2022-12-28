`ifndef BRCTYPE
    localparam BEQ   = 6'b 000000;
    localparam BNE   = 6'b 000001;
    localparam BLT   = 6'b 000100;
    localparam BGE   = 6'b 000101;
    localparam BLTU  = 6'b 000110;
    localparam BGEU  = 6'b 000111;
    localparam BNONE = 6'b 000010;
`define BRCTYPE
`endif
