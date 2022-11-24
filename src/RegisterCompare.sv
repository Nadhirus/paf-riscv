module RegisterCompare   (
    input logic[31:0] x1,
    input logic[31:0] x2,
    input logic[31:0] imm,
    input logic[2:0] op,
    output logic signed [12:0] incr
);
    `include "BRCTYPE.vh"

    always @(*)
        if (op == BEQ && $signed(x1) == $signed(x2) ||
            op == BNE && $signed(x1) != $signed(x2) ||
            op == BLT && $signed(x1) < $signed(x2)  ||
            op == BGE && $signed(x1) > $signed(x2)  ||
            op == BLTU && x1 < x2 ||
            op == BGEU && x1 > x2)
            incr <= imm[12:0];
        else
            incr <= 13'd4;

endmodule
