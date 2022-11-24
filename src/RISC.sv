module register #(parameter width=32) ( 
    input clk,
    input logic[width-1:0] D,
    input logic LOAD, 
    output logic[width-1:0] Q);

    always @(posedge clk)
        if(LOAD)
            Q <= D;
endmodule

module RISC (
    input logic            clk,
    input logic            reset_n,
    
    // RAM contenant les données
    output logic [31:0] d_address,
    input logic [31:0]  d_data_read,
    output logic [31:0] d_data_write,
    output logic        d_write_enable,
    input logic            d_data_valid,
    
    // ROM contenant les instructions
    output logic [31:0] i_address,
    input logic [31:0]  i_data_read,
    input logic            i_data_valid
    );
    
    `include "OPTYPE.vh"   

    //Instruction Fetch
    logic Load_instr;
    logic[31:0] instr;
    register #(.width(32)) reg_instr(.clk(clk), .D(i_data_read), .Q(instr), .LOAD(Load_instr));
    
    //Instruction Decode
    logic Load_decode;
    
    logic[4:0] rs1_in;
    logic[4:0] rs1;
    register #(.width(5)) reg_rs1(.clk(clk), .D(rs1_in), .Q(rs1), .LOAD(Load_decode));
    
    logic[4:0] rs2_in;
    logic[4:0] rs2;
    register #(.width(5)) reg_rs2(.clk(clk), .D(rs2_in), .Q(rs2), .LOAD(Load_decode));
    
    logic[4:0] rd_in;
    logic[4:0] rd;
    register #(.width(5)) reg_rd(.clk(clk), .D(rd_in), .Q(rd), .LOAD(Load_decode));
    
    logic[31:0] imm_in;
    logic[31:0] imm;
    register #(.width(32)) reg_imm(.clk(clk), .D(imm_in), .Q(imm), .LOAD(Load_decode));
    
    logic[3:0] ALU_op_in;
    logic[3:0] ALU_op;
    register #(.width(4)) reg_ALU_op(.clk(clk), .D(ALU_op_in), .Q(ALU_op), .LOAD(Load_decode));
    
    logic[2:0] BRC_op_in;
    logic[2:0] BRC_op;
    register #(.width(3)) reg_BRC_op(.clk(clk), .D(BRC_op_in), .Q(BRC_op), .LOAD(Load_decode));
    
    logic ch_op2_in;
    logic ch_op2;
    register #(.width(1)) reg_ch_op2(.clk(clk), .D(ch_op2_in), .Q(ch_op2), .LOAD(Load_decode));

    logic[1:0] ch_rd_in;
    logic[1:0] ch_rd;
    register #(.width(2)) reg_ch_rd(.clk(clk), .D(ch_rd_in), .Q(ch_rd), .LOAD(Load_decode));

    logic[6:0] opcode_in;
    logic[6:0] opcode;
    register #(.width(7)) reg_opcode(.clk(clk), .D(opcode_in), .Q(opcode), .LOAD(Load_decode));

    Decoder decoder(.instr(instr), .rs1(rs1_in), .rs2(rs2_in), .rd(rd_in), .imm(imm_in), .ALU_op(ALU_op_in), .BRC_op(BRC_op_in), .ch_op2(ch_op2_in), .ch_rd(ch_rd_in), .opcode(opcode_in));

    //Register selection
    logic[31:0] x1;
    logic[31:0] x2;
    logic[31:0] xd;
    logic Write_rd;

    RegisterBench regbench(.rs1(rs1), .rs2(rs2), .rd(rd), .xd(xd), .rd_en(Write_rd), .x1(x1), .x2(x2));

    //ALU
    logic[31:0] op1;
    logic[31:0] op2;
    
    logic Load_res;
    logic[31:0] ALU_res_in;
    logic[31:0] ALU_res;
    register #(.width(32)) reg_ALU_res(.clk(clk), .D(ALU_res_in), .Q(ALU_res), .LOAD(Load_res));

    always @(*)
        op1 <= x1;

    always @(*)
        if(ch_op2)
            op2 <= {{21{imm[11]}}, imm[11:0]};
        else
            op2 <= x2;

    ALU alu(.Op1(op1), .Op2(op2), .ALU_op(ALU_op), .res(ALU_res_in));

    //Memory manager
    always @(*)
        d_address <= x1 + imm;

    always @(*)
        d_data_write <= x2;

    logic[31:0] MEM_res;
    always @(*)
        MEM_res <= d_data_read;

    //Program Counter
    logic[31:0] loaded_addr;
    always @(*)
        loaded_addr <= x1 + imm;

    logic[31:0] incr;
    logic[12:0] incr_cmp;
    RegisterCompare reg_compare(.x1(x1), .x2(x2), .imm(imm), .op(BRC_op), .incr(incr_cmp));
    always @(*)
        if (opcode == AUIPC)
	        incr <= imm;
        else if (opcode == JAL)
            incr <= {{12{imm[20]}}, imm[19:0]};
        else
    	    incr <= {{20{incr_cmp[12]}}, incr_cmp[11:0]};

    logic[31:0] PC_res;
    logic[31:0] old_PC_res;
    logic Sel_addr;
    logic Inc_PC;

    ProgramCounter pc(.clk(clk), .reset_n(reset_n), .Sel_addr(Sel_addr), .Inc_PC(Inc_PC), .loaded_addr(loaded_addr), .incr(incr), .PC_res(PC_res), .old_PC_res(old_PC_res));

    always @(*)
        i_address <= PC_res;

    //WriteBack
    always@(*)
        if (ch_rd == 2'b00)
            xd <= ALU_res;
        else if (ch_rd == 2'b01)
            xd <= old_PC_res + 32'd4;
        else if (ch_rd == 2'b10)
            xd <= MEM_res;
        else if (opcode == LUI)
	        xd <= imm;
	    else
            xd <= 32'd0;

    //Control Unit
    ControlUnit ctrl(.clk(clk), .reset_n(reset_n), .opcode(opcode), .Load_instr(Load_instr), .Load_decode(Load_decode), .Write_rd(Write_rd), .Write_mem(d_write_enable), .Load_res(Load_res), .Sel_addr(Sel_addr), .Inc_PC(Inc_PC));

endmodule
