module Decoder  (  
        input logic[31:0] instr,
        output logic[4:0] rs1,
        output logic[4:0] rs2,
        output logic[4:0] rd,
        output logic[31:0] imm,
        output logic[3:0] ALU_op,
        output logic[2:0] BRC_op,
        output logic ch_op2,    //0 indicates op2 should be a register
        output logic[1:0] ch_rd, //0 for ALU, 1 for PC, 2 for MEM
        output logic[6:0] opcode
);

    `include "OPTYPE.vh"

    //Find the opcode
    always @(*)
        opcode <= instr[6:0];

    //Find rs1 which is usually at bits [19:15]
    always @(*)
        if (opcode != LUI && opcode != AUIPC && opcode != JAL)
            rs1 <= instr[19:15];
        else
            rs1 <= 5'b00000;

    //Find rs2 which is usually at bits [24:20]
    always @(*)
        if (opcode == BRANCH || opcode == STORE || opcode == REG_OP)
            rs2 <= instr[24:20];
        else
            rs2 <= 5'b00000;

    //Find rd which is usually at bits [11:7]
    always @(*)
        if (opcode != BRANCH && opcode != STORE)
            rd <= instr[11:7];
        else
            rd <= 5'b00000;

    //Find the immediate which is completely chaotic
    always @(*)
        if (opcode == LUI || opcode == AUIPC)
            imm <= {instr[31:12], 12'd0};
        else if (opcode == JAL)
            imm <= {11'd0, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        else if (opcode == BRANCH)
            imm <= {18'd0, instr[31], instr[7], instr[30:25], instr[12:8], 1'b0};
        else if (opcode == STORE)
            imm <= { {21{instr[31]}}, instr[30:25], instr[11:7]};
        else if(opcode == IMM_OP || opcode == JALR || opcode == LOAD)
            imm <= { {21{instr[31]}}, instr[30:20]};
        else
            imm <= 32'd0;

    //Find the ALU_op. We define it as the concatenation of instr[30]
    //which characterizes funct7, and funct3
    always @(*)
        if (opcode == REG_OP)
            ALU_op <= {instr[30], instr[14:12]};
        else if (opcode == IMM_OP)
            if (instr[14:12] == 3'b101)
                ALU_op <= {1'b1, instr[14:12]};
            else
                ALU_op <= {1'b0, instr[14:12]};
        else
            ALU_op <= 4'b1111;  //non used value

    always @(*)
        if(opcode == BRANCH)
            BRC_op <= instr[14:12];
        else
            BRC_op <= 3'b010;   //non used value

    always @(*)
        ch_op2 <= opcode == IMM_OP;

    always @(*)
        if (opcode == JAL || opcode == JALR || opcode == AUIPC)
            ch_rd <= 2'b01;
        else if (opcode == REG_OP || opcode == IMM_OP)
            ch_rd <= 2'b00;
        else if (opcode == LOAD)
            ch_rd <= 2'b10;
        else
            ch_rd <= 2'b11;

endmodule
