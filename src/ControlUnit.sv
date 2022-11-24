module ControlUnit  (
    input logic clk,
    input logic reset_n,
    input logic[6:0] opcode,

    output logic Load_instr,
    output logic Load_decode,
    output logic Write_rd,
    output logic Write_mem,
    output logic Load_res,
    output logic Sel_addr,
    output logic Inc_PC
);

    `include "OPTYPE.vh"

    enum logic[2:0] {IF, ID, EX, MEM, WB} state, n_state;

    always @(posedge clk or negedge reset_n)
        if(!reset_n)
            state <= IF;
        else
            state <= n_state;
 
    always @(*)
    begin
        n_state <= state;
        case(state)
            IF : n_state <= ID;
            ID : n_state <= EX;
            EX : n_state <= MEM;
            MEM : n_state <= WB;
            WB : n_state <= IF;
        endcase
    end

    always @(*)
        Load_instr <= state == IF;

    always @(*)
        Load_decode <= state == ID;

    always @(*)
        Load_res <= state == EX && (opcode == IMM_OP || opcode == REG_OP);

    always @(*)
        Write_mem <= state == MEM && opcode == STORE;

    always @(*)
        Write_rd <= state == WB;

    always @(*)
        Sel_addr <= state == MEM && opcode == JALR;

    always @(*)
        Inc_PC <= state == MEM;

endmodule
