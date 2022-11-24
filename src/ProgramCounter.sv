module ProgramCounter   (
          input logic clk,
          input logic reset_n,
          input logic Sel_addr,           
          input logic Inc_PC,           //equal to 1 when the pc can be incremented
          input logic[31:0] loaded_addr,
          input logic signed [31:0] incr,       //immediate value used for a jump's lenght
          output logic[31:0] PC_res,    //value of pc after a turn
          output logic[31:0] old_PC_res    //value of pc before the turn
);

    always @(posedge clk or negedge reset_n)
        if (! reset_n)
        begin
            PC_res <= 32'd0;
            old_PC_res <= 32'd0;
        end
        else

            if (Sel_addr)
                begin        
                    old_PC_res <= PC_res;
                    PC_res <= {loaded_addr[31:1], 1'b0};
                end
            else
                if (Inc_PC)
                    begin
                        old_PC_res <= PC_res;
                        PC_res <= PC_res + incr;
                    end
endmodule
