module pc_tb();

    logic clk;
    logic reset_n;
    logic Sel_addr;           //equal to 1 when the pc can be incremented
    logic Inc_PC;
    logic[31:0] loaded_addr;
    logic[31:0] incr;       //immediate value used for a jump's lenght
    logic[31:0] PC_res;

    ProgramCounter pc_test(.clk(clk),
               .reset_n(reset_n),
               .Sel_addr(Sel_addr),
               .Inc_PC(Inc_PC),
               .loaded_addr(loaded_addr),
               .incr(incr),
               .PC_res(PC_res));

    always
        begin
            #5ns
            clk <= !clk;
        end

    initial begin
        clk <= 0;
        reset_n <= 0;
        Inc_PC <= 0;

        #7ns
        reset_n <= 1;

        #10ns
        Inc_PC <= 1;

        #30ns
        Inc_PC <= 0;
    end

endmodule