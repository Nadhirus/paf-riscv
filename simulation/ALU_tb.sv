module ALU_tb();

    logic[31:0] Op1;
    logic[31:0] Op2;
    logic[3:0] ALU_op;
    logic[31:0] res;


    logic TEST;
    logic[31:0]  test_res;

    ALU ALU_test(.Op1(Op1),
                 .Op2(Op2),
                 .ALU_op(ALU_op),
                 .res(res));

    

    always
        begin
            #5ns
            Op1 <= $urandom();
            Op2 <= $urandom();
        end

    always
    begin
        #1ns
        TEST <= (res ==  test_res);

    end
        

    initial begin
        TEST <= 1'b0;

        #6ns
        ALU_op <=4'b0000;
        test_res <= Op1 + Op2;
        

        #5ns
        ALU_op <=4'b1000;
        test_res <= Op1 - Op2;

        #5ns
        ALU_op <=4'b0001;
        test_res <= Op1 << Op2[4:0];

        #5ns
        ALU_op <=4'b0010;
        test_res <= $signed(Op1) < $signed(Op2);

        #5ns
        ALU_op <=4'b0011;
        test_res <= Op1 < Op2;

        #5ns
        ALU_op <=4'b0100;
        test_res <= Op1 ^ Op2;

        #5ns
        ALU_op <=4'b0101;
        test_res <= Op1 >> Op2[4:0];

        #5ns
        ALU_op <=4'b0110;
        test_res <= Op1 | Op2;

        #5ns
        ALU_op <=4'b0111;
        test_res <= Op1 & Op2;

        #5ns
        ALU_op <=4'b1101;
        test_res <= $signed(Op1) >>> Op2[4:0];

    end

endmodule