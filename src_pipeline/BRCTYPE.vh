`ifndef BRCTYPE
    localparam BEQ   = 4'b0000;
    localparam BNE   = 4'b0001;
    localparam BLT   = 4'b0100;
    localparam BGE   = 4'b0101;
    localparam BLTU  = 4'b0110;
    localparam BGEU  = 4'b0111;
    localparam BNONE = 4'b0010;
`define BRCTYPE
`endif
