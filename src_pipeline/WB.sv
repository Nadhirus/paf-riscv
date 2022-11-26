module WB   (
    input logic[31:0] d_data_read,
    input logic[31:0] res,
    input logic[31:0] PC,
    input logic[6:0] opcode,

    output logic[31:0] xd
);

    `include "OPTYPE.vh"

    //If the operation is LOAD, the output will be d_data_read
    //If AUIPC, JAL, JALR, we save the pc + 4 in rd
    //Else res is returned, as rd = 0 if it is not necessary to have
    //a WB.
    always @(*)
        if (opcode == LOAD)
            xd = d_data_read;
        else if (opcode == AUIPC || opcode == JAL || opcode == JALR)
            xd = PC + 32'd4;
        else
            xd = res;

endmodule
