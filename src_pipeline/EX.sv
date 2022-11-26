module EX(
          input clk, reset_n,
          input logic[4:0] rs1,
          input logic[4:0] rs2,
          output logic[31:0] rs1_value,
          output logic[31:0] rs2_value,

          input logic[4:0] rd_WB,
          input logic[31:0] res_WB,
          input logic[31:0] imm,
          input logic[3:0] op_EX,
          input logic[6:0] opcode_EX,
          input logic[31:0] PC,
          input logic[4:0] rd_MEM, // used for data forwarding
          input logic[31:0] res_MEM,
          output logic[31:0] res,
          output logic[31:0] x2_EX,
          output logic       trap
        );
    
    reg [31:0] regs[31:0];
    logic [31:0] Op1;
    logic [31:0] Op2;

    logic [31:0] x1;
    

    //Register Bench
    `include "OPTYPE.vh"

    initial
        regs[0] = 0;


    assign rs1_value = x1;
    assign rs2_value = x2_EX;

    always @(*)
    begin
        if (rs1 != 5'd0)
        begin
            if (rd_MEM == rs1)
                x1 = res_MEM;
            else if (rd_WB == rs1)
                x1 = res_WB;
            else 
                x1 = regs[rs1];
        end
        else 
            x1 = regs[rs1];
        
        if (rs2 != 5'd0)
        begin
            if (rd_MEM == rs2)
                x2_EX = res_MEM;
            else if (rd_WB == rs2)
                x2_EX = res_WB;
            else 
                x2_EX = regs[rs2];
        end
        else 
            x2_EX = regs[rs2];
    end


// store: [rs1 + sx(imm)] <= rs2
    always @(*)
        if(opcode_EX == IMM_OP 
        || opcode_EX == LUI 
        || opcode_EX == AUIPC
        || opcode_EX == JALR 
        || opcode_EX == LOAD 
        || opcode_EX == STORE)
//JAL
//BRANCH
//REG_OP
                Op2 = imm;
            else
                Op2 = x2_EX;


    assign Op1 = (opcode_EX == AUIPC) ? PC : x1;

    

    always @(posedge clk) begin
        if(!reset_n) begin
            int i;
            for(i = 0; i < 32; i++)
                regs [i] <= '0;
        end
        else begin
            if (rd_WB != 0)
            regs [rd_WB] <= res_WB;
        end

    end

    `include "BRCTYPE.vh"
    `include "ALUTYPE.vh"

    always @(*) begin
        trap = 0;
        //Register Compare
        if (opcode_EX == BRANCH) begin
            res = (op_EX == BEQ && Op1 == Op2 ||
                    op_EX == BNE && Op1 != Op2 ||
                    op_EX == BLT && $signed(Op1) < $signed(Op2)  ||
                    op_EX == BGE && $signed(Op1) >= $signed(Op2)  ||
                    op_EX == BLTU && Op1 < Op2 ||
                    op_EX == BGEU && Op1 >= Op2) ? 1 : 0;

            trap = (imm[1:0] != 0) && res;
        end
        //ALU
        else if (opcode_EX == IMM_OP || opcode_EX == REG_OP)
            begin
                case(op_EX)
                    SUB : res = Op1 - Op2;
                    SLL : res = Op1 << Op2[4:0];
                    SLT : res = ($signed(Op1) < $signed(Op2)) ? 1 : 0;
                    SLTU: res = (Op1 < Op2) ? 1 : 0;
                    XOR : res = Op1 ^ Op2;
                    SRL : res = Op1 >> Op2[4:0];
                    SRA : res = $signed(Op1) >>> Op2[4:0];
                    OR  : res = Op1 | Op2;
                    AND : res = Op1 & Op2;
                    default /*ADD*/ : res = Op1 + Op2;
                endcase
            end
        else if(opcode_EX == AUIPC)
            res = Op1 + Op2;
        else if (opcode_EX == LOAD || opcode_EX == STORE || opcode_EX == LUI)
            begin
                res  = Op1 + Op2;
                trap = res[1:0] != 0;
            end
        else if(opcode_EX == JALR)
            begin
                res = (Op1 + Op2) & ~32'b01;
                trap = res[1:0] != 0;
                    
            end
        else if(opcode_EX == JAL) begin
            res  = imm;
            trap = imm[1:0] != 0;
        end
        else
            res = imm;
    end


        
        
endmodule
