module ID   (
    //The instruction is sent directly from the ROM after IF
    //module indicates the address of the next intrusction
    input logic[31:0] instr,

    //The decoder determines which registers will be used.
    //In case the operation does not require a certain register
    //the decoder set its index to 0, such that the hardcoded
    //register 0 will be used.
    output logic[4:0] rs1,
    output logic[4:0] rs2,
    output logic[4:0] rd,
    
    //The immediate can vary much depending on the instruction.
    //The decoder sends a sign extended immediate value if
    //required, and pad it with zeros.
    output logic[31:0] imm,

    //The opcode and op outputs indicate which operation is
    //executed. The opcode is very general, it tells the type of
    //the operation that is executed. The op brings complementary
    //information
    output logic[6:0] opcode,
    output logic[3:0] op,

    // invalid instruction
    output logic      ill
);


    `include "OPTYPE.vh"

    assign opcode = instr[6:0];


    wire [2:0]func3 = instr[14:12];
    wire [6:0]func7 = instr[31:25];

    always_comb begin
        // check instruction illness
        ill = 0;
        case(opcode)
            LUI   : ;
            AUIPC : ;
            JAL   : ;
            JALR  : ill = (func3 != 3'b0);
            BRANCH: ill = (func3 == 3'b010 || func3 == 3'b011);
            LOAD  : ill = (func3 == 3'b011 || func3 == 3'b111 || func3 == 3'b110);
            STORE : ill = (func3 >  3'b010);
            IMM_OP: begin
                case(func3)
                    3'b001: ill = (func7 != 7'b0000000);
                    3'b101: ill = (func7 != 7'b0000000 && func7 != 7'b0100000);
                    default: ;
                endcase
            end
            REG_OP: begin
                    ill = 1;
                case(func3)
                    3'b000: ill  = (func7 != 7'b0000000 && func7 != 7'b0100000);
                    3'b101: ill  = (func7 != 7'b0000000 && func7 != 7'b0100000);
                    default:ill  = (func7 != 7'b0000000);
                endcase
            end
            default: ill = 1;
        endcase
    end

    //op is the concatenation of a characteristic bit of funct7
    //if it exists and funct3. When associated with opcode,
    //it gives a unique identifier for any operation.
    //As funct7 is not used in many cases and funct3 is at a
    //static position, we prefer to differentiate the
    //3 operations having a 1 as funct7.
    //THERE IS NO DEFAULT OP.
    always @(*)
        if ((opcode == IMM_OP && 
             (instr[14:12] == 3'b101)) ||
            (opcode == REG_OP &&
             (instr[14:12] == 3'b000 ||
              instr[14:12] == 3'b101))     )
            op <= {instr[30], instr[14:12]};
        else
            op <= {1'b0, instr[14:12]};

    //The three registers are both at static positions, but not
    //used by every instruction. If an instruction does not
    //require some register, it is set to 0 by default.

    //Register source 1 is used in every operation except
    //LUI, AUIPC, JAL
    always @(*)
        if (!(opcode == LUI || opcode == AUIPC || opcode == JAL))
            rs1 <= instr[19:15];
        else
            rs1 <= 5'h00;

    //Register source 2 is used by BRANCH, STORE and REG_OP
    //operations
    always @(*)
        if (opcode == BRANCH || opcode == STORE || opcode == REG_OP)
            rs2 <= instr[24:20];
        else
            rs2 <= 5'h00;

    //Register of destination is not used by BRANCH and STORE
    //operations
    always @(*)
        if (!(opcode == BRANCH || opcode == STORE))
            rd <= instr[11:7];
        else
            rd <= 5'h00;

    //Immediate value format varies much depending on the opcode.
    //In every case though it is sign extended. To do so, we
    //extend the strongest bit (its position depend on the opcode)
    //in order to have it fill the strongest bits.
    always @(*)
        //In case opcode is LUI or AUIPC, the immediate is
        //32-bit long, but is filled with 0 for the 12 least
        //significant bits.
        if (opcode == LUI || opcode == AUIPC)
            imm <= {instr[31:12], 12'h000};
        //For JAL, the immediate is more complex and is 20-bit
        //long.
        else if (opcode == JAL)
            imm <= {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        //Same for BANCH, but the immediate is 13-bit long and
        //has its first bit set to 0
        else if (opcode == BRANCH)
            imm <= {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        //For STORE, the immediate is 12-bit long
        else if (opcode == STORE)
            imm <= {{21{instr[31]}}, instr[30:25], instr[11:7]};
        //For LOAD, JALR and IMM_OP (shamt is unaffected as EX
        //treats it
        else if (opcode == LOAD || opcode == JALR || opcode == IMM_OP)
            imm <= {{21{instr[31]}}, instr[30:20]};
        //If REG_OP, or by default, imm is 0
        else
            imm <= 32'd0;

endmodule
