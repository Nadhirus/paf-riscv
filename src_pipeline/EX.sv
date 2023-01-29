module EX(
          input clk, reset_n,
          input logic[4:0] rs1,
          input logic[4:0] rs2,
          output logic[31:0] rs1_value,
          output logic[31:0] rs2_value,

          input            ext_stall,
          input logic[4:0] rd_WB,
          input logic[31:0] res_WB,
          input logic[31:0] imm,
          input logic[5:0] op_EX,
          input logic[6:0] opcode_EX,
          input logic[1:0] barrel_shift,
          input logic[31:0] PC,
          input logic[4:0] rd_MEM, // used for data forwarding
          input logic[31:0] res_MEM,
          input      [ 1:0] ldsz,
          output     [ 1:0] ldshift,
          output logic[31:0] res,
          output logic[31:0] x2_EX,
          output logic       stall_req,
          output logic       trap
        );

    
    reg [31:0] regs[31:0];
    logic [31:0] Op1;
    logic [31:0] Op2;

    logic [31:0] x1;
    

    //Register Bench
    `include "OPTYPE.vh"
    
    // zbb complex functions
    `include "zbb.vh"

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


    wire [31:0] sum = (Op1 << barrel_shift) + Op2;

    `include "BRCTYPE.vh"
    `include "ALUTYPE.vh"


    //////////////////////////////////
    ///// Bit manip instructions /////
    //////////////////////////////////
    wire [63:0] clmul;
    wire [ 5:0] cpop;
    wire [ 5:0] ctz;
    wire [ 5:0] clz;

    wire clmul_stall_req;
    wire clmul_comp = opcode_EX == REG_OP && 
                        (op_EX == CLMUL 
                      || op_EX == CLMULH 
                      || op_EX == CLMULR);
    (* keep *) wire clmul_done;

    logic clmul_running;
    always_ff @(posedge clk)
        if(!reset_n)
            clmul_running <= 0;
        else begin
            if(!ext_stall) begin
                if(clmul_comp)
                    clmul_running <= 1;
                
                if(!clmul_stall_req)
                    clmul_running <= 0;
            end
        end

    wire clmul_start = clmul_comp && !clmul_running;
    assign clmul_stall_req = clmul_comp && !clmul_done;

    clmul clmul_i(
        .clk   (clk    ),
        .resetn(reset_n),
        .start (clmul_start),
        .stall (ext_stall),
        .eoc   (clmul_done),
        .A     (Op1    ),
        .B     (Op2    ),
        .res   (clmul  )
    );
    
    cpop cpop_i(
        .x  (Op1 ),
        .res(cpop)
    );

    ctz ctz_0(
        .x  (Op1),
        .res(ctz)
    );

    // only the CLMUL unit stalls
    assign stall_req = clmul_stall_req;


    wire [31:0] Op1_rev;
    // for clz 
    ctz ctz_1(
        .x  (Op1_rev), // Op1 with reversed bit order
        .res(clz)
    );


    generate
        genvar i;
        for(i = 0; i < 32; i++) begin: gen_Op1_rev
            assign Op1_rev[i] = Op1[31 - i];
        end
    endgenerate


    wire less          = $signed(Op1) <  $signed(Op2);
    wire greater_or_eq = $signed(Op1) >= $signed(Op2);

    wire less_u          = Op1 <  Op2;
    wire greater_or_eq_u = Op1 >= Op2;


    // multiplex the shifters operators to only use two
    // shifters for every shift operation.
    wire [4:0] shl_op2 = (op_EX == ROR) ? (32 - Op2[4:0]) : Op2[4:0];
    wire [4:0] shr_op2 = (op_EX == ROL) ? (32 - Op2[4:0]) : Op2[4:0];
    
    wire shr_arithmetic = op_EX == SRA;


    wire [31:0] shl_op1 = (op_EX == BCLR ||
                           op_EX == BINV ||
                           op_EX == BSET) ? 1 : Op1;

    wire [31:0] shl = shl_op1 << shl_op2;
    logic [31:0] shr;

    always_comb
        if(shr_arithmetic)
            shr = $signed(Op1) >>> shr_op2;
        else
            shr = Op1 >> shr_op2;

            

    always @(*) begin
        trap = 0;
        //Register Compare
        if (opcode_EX == BRANCH) begin
            res = (op_EX == BEQ && Op1 == Op2 ||
                   op_EX == BNE && Op1 != Op2 ||
                   op_EX == BLT && less  ||
                   op_EX == BGE && greater_or_eq  ||
                   op_EX == BLTU && less_u ||
                   op_EX == BGEU && greater_or_eq_u) ? 1 : 0;

            trap = (imm[1:0] != 0) && res[0];
        end
        //ALU
        else if (opcode_EX == IMM_OP || opcode_EX == REG_OP)
            begin
                case(op_EX)
                    SUB :  res = Op1 - Op2;
                    SLL :  res = shl;
                    SLT :  res = less ? 1 : 0;
                    SLTU:  res = (less_u) ? 1 : 0;
                    XOR :  res = Op1 ^ Op2;
                    SRL :  res = shr;
                    SRA :  res = shr;
                    OR  :  res = Op1 | Op2;
                    AND :  res = Op1 & Op2;
                     
                    // bitmanip
                    ORN  : res = Op1 |~Op2;
                    ANDN : res = Op1 &~Op2;
                    XNOR : res = ~(Op1 ^ Op2);
                    CLZ  : res = {26'h0, clz};
                    CTZ  : res = {26'h0, ctz};
                    CPOP : res = {26'h0, cpop};
                    SEXTB: res = $signed(Op1[ 7:0]);
                    SEXTH: res = $signed(Op1[15:0]);
                    ZEXTH: res = {16'h0, Op1[15:0]};
                    ORCB : res = orcb32(Op1);
                    REV8 : res = rev8_32(Op1);

                    CLMUL: res = clmul[31: 0];
                    CLMULH:res = clmul[63:32];
                    CLMULR:res = clmul[62:31];

                    MAX  : res = less   ? Op2 : Op1;
                    MAXU : res = less_u ? Op2 : Op1;
                    MIN  : res = less   ? Op1 : Op2;
                    MINU : res = less_u ? Op1 : Op2;
                    ROR  : res = shl | shr;
                    ROL  : res = shl | shr;

                    BCLR : res = Op1 & ~shl;
                    BEXT : res = {31'b0, shr[0]};
                    BINV : res = Op1 ^ shl;
                    BSET : res = Op1 | shl;


                    default /*ADD*/ : res = sum;
                endcase
            end
        else if(opcode_EX == AUIPC)
            res = sum;
        else if (opcode_EX == LUI)
            begin
                res  = sum;
                trap = res[1:0] != 0;
            end
        else if(opcode_EX == LOAD || opcode_EX == STORE) begin
            res = sum & ~32'b11;

            trap = (ldsz == 2'b01) && (sum[0:0] != 0)  // LH
                || (ldsz == 2'b11) && (sum[1:0] != 0); // LW
        end
        else if(opcode_EX == JALR)
            begin
                res = sum & ~32'b01;
                trap = res[1:0] != 0;
                    
            end
        else if(opcode_EX == JAL) begin
            res  = imm;
            trap = imm[1:0] != 0;
        end
        else
            res = imm;
    end


    assign ldshift = sum[1:0];

endmodule
