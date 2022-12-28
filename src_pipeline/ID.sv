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
    output logic[5:0] op,
    output logic[1:0] barrel_shift,

    // 0: undefined
    // 1: load byte
    // 2: load half
    // 3: load word
    output [1:0] ldsz,
    output       ldsx,

    // invalid instruction
    output logic      ill
);


    `include "OPTYPE.vh"

    assign opcode = instr[6:0];

 
    wire [2:0] func3 = instr[14:12];
    wire [6:0] func7 = instr[31:25];
    
    // for B extension
    wire [4:0] func5 = instr[24:20];

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


        // ZBA
        barrel_shift = 0;
        if(opcode == REG_OP && func7 == 7'b0010000) begin
            ill = 0;
            // Zba (sh1add, sh2add, sh3add)
            case(func3) 
                3'b010: barrel_shift = 1;
                3'b100: barrel_shift = 2;
                3'b110: barrel_shift = 3;
                default: ill = 1;
            endcase
        end

        // ZBB
        if(opcode == REG_OP && func7 == 7'b 0100000) begin
            ill = 0;
            case(func3)
                3'b111: /* andn */ ;
                3'b110: /* orn  */ ;
                3'b100: /* xnor */ ;
                3'b000: /* sub  */ ;
                3'b101: /* srai */ ;

                default: ill = 1;
            endcase
        end
        else if(opcode == IMM_OP && func3[1:0] == 2'b01) begin
            if(func7 == 7'b 0010100) begin
                ill = 0;
                casez({func5, func3})
                    8'b 00111_101: /* orc.b */ ;
                    8'b zzzzz_001: /* bseti */ ;
                    default: ill = 1;
                endcase
            end
            else if(func7 == 7'b 0110100) begin
                ill = 0;
                casez({func5, func3})
                    8'b 11000_101: /* rev8 */ ;
                    8'b zzzzz_001: /* binvi */;
                    default: ill = 1;
                endcase
            end
            else if(func7 == 7'b 0110000) begin
                ill = 0;
                // clz, ctz, cpop, sext.b, sext.h
                case(func5)
                    5'b 00000: /* clz    */;
                    5'b 00001: /* ctz    */;
                    5'b 00010: /* cpop   */;
                    5'b 00100: /* sext.b */;
                    5'b 00101: /* sext.h */;
                    default: ill = 1;
                endcase
                if(func3 != 3'b001)
                    ill = 1;
            end
            else if(func7 == 7'b 0100100) begin
                ill = 0;
                case(func3)
                    3'b 001: /* bclri */;
                    3'b 101: /* bexti */;
                    default: ill = 1;
                endcase
            end
        end
        else if(opcode == REG_OP) begin
            if(func7 == 7'b 0000101) begin
                ill = 0;
                // clmul
                case(func3)
                    3'b 001: /* clmul  */;
                    3'b 011: /* clmulh */;
                    3'b 010: /* clmulr */;
                    default: ill = 1;
                endcase
            end
            else if(func7 == 7'b 0100100) begin
                ill = 0;
                case(func3)
                    3'b 001: /* bclr */;
                    3'b 101: /* bext */;
                    default: ill = 1;
                endcase 
            end
            else if(func7 == 7'b 0010100) begin
                ill = 0;
                case(func3)
                    3'b 001: /* bset */;
                    default: ill = 1;
                endcase
            end
            else if(func7 == 7'b 0110100) begin
                ill = 0;
                case(func3) 
                    3'b 001: /* binv */;
                    default: ill = 1;
                endcase
            end
        end
    end


    always_comb begin
        case(func3)
            3'b 000: /* LB  / SB  */ {ldsx,ldsz} = 3'b1_00;
            3'b 001: /* LH  / SH  */ {ldsx,ldsz} = 3'b1_01;
            3'b 010: /* LW  / SW  */ {ldsx,ldsz} = 3'b0_11;
            3'b 100: /* LBU / SBU */ {ldsx,ldsz} = 3'b0_00;
            3'b 101: /* LHU / SHU */ {ldsx,ldsz} = 3'b0_01;
            default: {ldsx,ldsz} = 3'b0_00;
        endcase
    end

    //op is the concatenation of a characteristic bit of funct7
    //if it exists and funct3. When associated with opcode,
    //it gives a unique identifier for any operation.
    //As funct7 is not used in many cases and funct3 is at a
    //static position, we prefer to differentiate the
    //3 operations having a 1 as funct7.
    //THERE IS NO DEFAULT OP.


    always @(*) begin
        if (opcode == IMM_OP) begin
            if(func3[1:0] == 2'b01)
                op = {1'b0, func7[4], func7[5], func3};
                // SRAI
            else
                op = {3'b0, func3};
        end
        else if(opcode == REG_OP) begin
            op = {1'b0, func7[4], func7[5], func3};
        end
        else
            op = {3'b0, func3};

        if((opcode == IMM_OP && func3[1:0] == 2'b01) || opcode == REG_OP) begin
            
            // Zba, Zbb, Zbc, Zbs
            if(func7 == 7'b 0010000)
                op = 0; // ADD (with barrel shifter)
            else if(func7 == 7'b 0110000) 
                op[2:0] = func5[2:0];
            else if(func7 == 7'b 0010100) begin
                if(func3[2])// orc.b
                    op[2:0] = 3'b111;
                else begin // bset
                    op[2:0] = 3'b001;
                    op[5] = 1'b1;
                end
            end
            else if(func7 == 7'b 0110100) begin
                if(func3[2]) // rev8
                    op[2:0] = 3'b011;
                else begin// binv
                    op[2:0] = 3'b001;
                    op[5] = 1'b1;
                end
            end

            if(func7 == 7'b 0000101
            || func7 == 7'b 0100100)
                op[5] = 1'b1; // bclr / bclri / bext / bexti / clmul / clmulh / clmulr
        end
    end
    
    //The three registers are both at static positions, but not
    //used by every instruction. If an instruction does not
    //require some register, it is set to 0 by default.

    //Register source 1 is used in every operation except
    //LUI, AUIPC, JAL
    always @(*)
        if (!(opcode == LUI || opcode == AUIPC || opcode == JAL))
            rs1 = instr[19:15];
        else
            rs1 = 5'h00;

    //Register source 2 is used by BRANCH, STORE and REG_OP
    //operations
    always @(*)
        if (opcode == BRANCH || opcode == STORE || opcode == REG_OP)
            rs2 = instr[24:20];
        else
            rs2 = 5'h00;

    //Register of destination is not used by BRANCH and STORE
    //operations
    always @(*)
        if (!(opcode == BRANCH || opcode == STORE))
            rd = instr[11:7];
        else
            rd = 5'h00;

    //Immediate value format varies much depending on the opcode.
    //In every case though it is sign extended. To do so, we
    //extend the strongest bit (its position depend on the opcode)
    //in order to have it fill the strongest bits.
    always @(*)
        //In case opcode is LUI or AUIPC, the immediate is
        //32-bit long, but is filled with 0 for the 12 least
        //significant bits.
        if (opcode == LUI || opcode == AUIPC)
            imm = {instr[31:12], 12'h000};
        //For JAL, the immediate is more complex and is 20-bit
        //long.
        else if (opcode == JAL)
            imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        //Same for BANCH, but the immediate is 13-bit long and
        //has its first bit set to 0
        else if (opcode == BRANCH)
            imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        //For STORE, the immediate is 12-bit long
        else if (opcode == STORE)
            imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};
        //For LOAD, JALR and IMM_OP (shamt is unaffected as EX
        //treats it
        else if (opcode == LOAD || opcode == JALR || opcode == IMM_OP)
            imm = {{21{instr[31]}}, instr[30:20]};
        //If REG_OP, or by default, imm is 0
        else
            imm = 32'd0;

endmodule
