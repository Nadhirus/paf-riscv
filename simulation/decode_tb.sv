module decode_tb();

    logic[31:0] instr;
    logic[4:0] rs1;
    logic[4:0] rs2;
    logic[4:0] rd;
    logic[31:0] imm;
    logic[3:0] ALU_op;
    logic[2:0] BRC_op;
    logic ch_op1;
    logic ch_op2;

    //test variables
    logic[31:0] imt; //immediate test variable

    logic[6:0] test_func7;
    logic[4:0] test_rs2;
    logic[4:0] test_rs1;
    logic[2:0] test_func3;
    logic[4:0] test_rd;
    logic[6:0] test_opcode;



    decode decode_test(.instr(instr), .rs1(rs1), .rs2(rs2), .rd(rd), .imm(imm), .ALU_op(ALU_op), .BRC_op(BRC_op), .ch_op1(ch_op1), .ch_op2(ch_op2));

    always
        begin
            #10ns
            instr <= {test_func7, test_rs2, test_rs1, test_func3, test_rd, test_opcode}; 
        end


    initial begin

        instr <=32'd0;
        #11ns
        test_rs1 <= 5'd5;
        test_rs2 <= 5'd4;
        test_rd  <= 5'd31;
        test_func7 <= 7'b000_0000;
        test_func3 <= 3'b000;
        test_opcode <= 7'b0110011;
        //ADD test_rd,test_rs1,test_rs2 

        #10ns

        assert(rs1 == test_rs1);
        assert(rs2 == test_rs2);
        assert(rd == test_rd);

        #1ns

        test_rs1 <= 5'd15;
        imt <= 32'd1;
        test_rd  <= 5'd1;
        #1ns
        {test_func7, test_rs2} <= imt[11:0];
        test_func3 <= 3'b110;
        test_opcode <= 7'b0010011;
        //ORI test_rd,test_rs1,imt

        #9ns

        assert(rs1 == test_rs1);
        assert(imm == imt);
        assert(rd == test_rd);

        test_rs1 <= 5'd13;
        test_rs2 <= 5'd31;
        test_func3 <= 3'b001;
        imt <= 32'hffff_fff0;
        #1ns
        {test_func7, test_rd} <= {imt[12], imt[10:1], imt[11]};
        test_opcode <= 7'b1100011;
        //BNE imt,test_rs1,test_rs2

        #10ns

        assert(rs1 == test_rs1);
        assert(imm == imt);

        imt <= 32'hffff_fff0;
        test_rd  <= 5'd10;
        {test_func7, test_rs1, test_rs2, test_func3} <= {imt[20], imt[10:1], imt[11], imt [19:12]};
        test_opcode <= 7'b1101111;
        //JAL test_rd, imt

    end


endmodule