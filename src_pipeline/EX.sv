module EX(input logic[4:0] rs1,
          input logic[4:0] rs2,
          output logic[31:0] rs1_value,
          output logic[31:0] rs2_value,

          input logic[4:0] rd_WB,
          input logic[31:0] res_WB,
          input logic[31:0] imm,
          input logic[3:0] op_EX,
          input logic[6:0] opcode_EX,
          input logic[4:0] rd_MEM, // used for data forwarding
          input logic[31:0] res_MEM,
          output logic[31:0] res,
          output logic[31:0] x2_EX
        );
    
    logic[31:0] regs[31:0];
    logic [31:0] Op1;
    logic [31:0] Op2;
    

    //Register Bench
    `include "OPTYPE.vh"

    initial
        regs[0] = 0;


    assign rs1_value = regs[rs1];
    assign rs2_value = regs[rs2];

    always @(*)
    begin
        if (rs1 != 5'd0)
        begin
            if (rd_MEM == rs1)
                Op1 <= res_MEM;
            else if (rd_WB == rs1)
                Op1 <= res_WB;
            else 
                Op1 <= regs[rs1];
        end
        else 
            Op1 <= regs[rs1];
        
        if (rs2 != 5'd0)
        begin
            if (rd_MEM == rs2)
                x2_EX <= res_MEM;
            else if (rd_WB == rs2)
                x2_EX <= res_WB;
            else 
                x2_EX <= regs[rs2];
        end
        else 
            x2_EX <= regs[rs2];
    end

    always @(*)
        if(opcode_EX == IMM_OP || opcode_EX == LUI || opcode_EX == JALR || opcode_EX == LOAD || opcode_EX == STORE)
                Op2 <= imm;
            else
                Op2 <= x2_EX;

    always @(*)
        if (rd_WB != 0)
            regs [rd_WB] <= res_WB;

    `include "BRCTYPE.vh"
    `include "ALUTYPE.vh"
    always @(*)
        //Register Compare
        if (opcode_EX == BRANCH)
            res <= (op_EX == BEQ && Op1 == Op2 ||
                    op_EX == BNE && Op1 != Op2 ||
                    op_EX == BLT && $signed(Op1) < $signed(Op2)  ||
                    op_EX == BGE && $signed(Op1) > $signed(Op2)  ||
                    op_EX == BLTU && Op1 < Op2 ||
                    op_EX == BGEU && Op1 > Op2);

        //ALU
        else if (opcode_EX == IMM_OP || opcode_EX == REG_OP)
            begin
                case(op_EX)
                    SUB : res <= Op1 - Op2;
                    SLL : res <= Op1 << Op2[4:0];
                    SLT : res <= $signed(Op1) < $signed(Op2);
                    SLTU: res <= Op1 < Op2;
                    XOR : res <= Op1 ^ Op2;
                    SRL : res <= Op1 >> Op2[4:0];
                    SRA : res <= $signed(Op1) >>> Op2[4:0];
                    OR : res <= Op1 | Op2;
                    AND : res <= Op1 & Op2;
                    default /*ADD*/ : res <= Op1 + Op2;
                endcase
            end

        else if (opcode_EX == LOAD || opcode_EX == STORE || opcode_EX == LUI)
            begin
                res <= Op1 + Op2;
            end
        else if(opcode_EX == JALR)
            begin
                res <= (Op1 + Op2) & ~32'b11;
            end
        else
            res <= imm;

        
        
endmodule
