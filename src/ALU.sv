
`ifndef INSTRUCTIONS
localparam ADD = 4'b0000;
localparam SUB = 4'b1000;
localparam SLL = 4'b0001;
localparam SLT = 4'b0010;
localparam SLTU= 4'b0011;
localparam XOR = 4'b0100;
localparam SRL = 4'b0101;
localparam SRA = 4'b1101;
localparam  OR = 4'b0110;
localparam AND = 4'b0111;
`define INSTRUCTIONS
`endif

module ALU(input logic[31:0] Op1,
           input logic[31:0] Op2,
           input logic[3:0] ALU_op,
           output logic[31:0] res
           );
    
    always @(*) 
        begin
            case(ALU_op)
                
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
        
endmodule
