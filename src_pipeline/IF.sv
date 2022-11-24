module IF   (
    input logic clk,
    input logic reset_n,

    input logic jump,
    input logic[31:0] jumpaddr,


    //the address of the instruction in the ROM.
    output logic[31:0] i_addr
);

    `include "OPTYPE.vh"

    logic [31:0] PC;

    //We calculate the new value of PC in the case of a jump
    //If JALR, we must replace PC by the res value of EX module
    //If AUIPC, JAL, BRANCH, the value can be replaced by imm + PC.

    always @(*)
        if (jump)
            i_addr <= jump;
        else
            i_addr <= PC;

    always @(posedge clk or negedge reset_n)
        if(!reset_n)
            PC <= 32'h00000000;
        else
            PC <= i_addr + 32'd4;

endmodule
