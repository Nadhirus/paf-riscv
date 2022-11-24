module register #(parameter width=32) ( 
    input logic clk,
    input logic RAZ,
    input logic[width-1:0] D,
    output logic[width-1:0] Q);

    always @(posedge clk)
        if(RAZ)
            Q <= 0;
        else
            Q <= D;

endmodule





module RISC #(
        localparam NRET = 1,
        localparam ILEN = 32
    ) (
    input logic            clk,
    input logic            reset_n,
    
    // RAM contenant les données
    output logic [31:0] d_address,
    input logic [31:0]  d_data_read,
    output logic [31:0] d_data_write,
    output logic        d_write_enable,
    input logic         d_data_valid,
    
    // ROM contenant les instructions
    output logic [31:0] i_address,
    input logic [31:0]  i_data_read,
    input logic         i_data_valid

    `ifdef RVFI_TRACE
    // rvfi interface
    ,
    output [NRET          - 1 : 0] rvfi_valid,
    output [NRET *   64   - 1 : 0] rvfi_order,
    output [NRET * ILEN   - 1 : 0] rvfi_insn,
    output [NRET          - 1 : 0] rvfi_trap,
    output [NRET          - 1 : 0] rvfi_halt,
    output [NRET          - 1 : 0] rvfi_intr,
    output [NRET * 2      - 1 : 0] rvfi_mode,
    output [NRET * 2      - 1 : 0] rvfi_ixl,
    output [NRET *    5   - 1 : 0] rvfi_rs1_addr,
    output [NRET *    5   - 1 : 0] rvfi_rs2_addr,
    output [NRET * XLEN   - 1 : 0] rvfi_rs1_rdata,
    output [NRET * XLEN   - 1 : 0] rvfi_rs2_rdata,
    output [NRET *    5   - 1 : 0] rvfi_rd_addr,
    output [NRET * XLEN   - 1 : 0] rvfi_rd_wdata,
    output [NRET * XLEN   - 1 : 0] rvfi_pc_rdata,
    output [NRET * XLEN   - 1 : 0] rvfi_pc_wdata,
    output [NRET * XLEN   - 1 : 0] rvfi_mem_addr,
    output [NRET * XLEN/8 - 1 : 0] rvfi_mem_rmask,
    output [NRET * XLEN/8 - 1 : 0] rvfi_mem_wmask,
    output [NRET * XLEN   - 1 : 0] rvfi_mem_rdata,
    output [NRET * XLEN   - 1 : 0] rvfi_mem_wdata
    `endif
    );
    
    `include "OPTYPE.vh"   

    //KILL signals for setting internal registers to 0 and create
    //bubble.
    //logic kill_to_ID;
    logic kill_to_EX;
    //logic kill_to_MEM;
    //logic kill_to_WB;

    wire ill_ID;
    logic trap;

    always_ff @(posedge clk) begin
        if(!reset_n)
            trap <= 0;
        else begin
            if(ill_ID)
                trap <= 1;
        end
    end

    //Value of PC must be propagated from IF module all the way to WB module
    logic[31:0] PC_IF;
    logic[31:0] PC_ID;
    logic[31:0] PC_EX;
    logic[31:0] PC_MEM;
    logic[31:0] PC_WB;
    register #(.width(32)) PC_to_ID(.clk(clk), .D(PC_IF), .Q(PC_ID), .RAZ(kill_to_ID));
    register #(.width(32)) PC_to_EX(.clk(clk), .D(PC_ID), .Q(PC_EX), .RAZ(kill_to_EX));
    register #(.width(32)) PC_to_MEM(.clk(clk), .D(PC_EX), .Q(PC_MEM), .RAZ(kill_to_MEM));
    register #(.width(32)) PC_to_WB(.clk(clk), .D(PC_MEM), .Q(PC_WB), .RAZ(kill_to_WB));

    //Value of rd must be propagated follow the instruction from
    //ID to WB and then return to EX.
    logic[4:0] rd_ID;
    logic[4:0] rd_EX;
    logic[4:0] rd_MEM;
    logic[4:0] rd_WB;
    register #(.width(5)) rd_to_EX(.clk(clk), .D(rd_ID), .Q(rd_EX), .RAZ(kill_to_EX));
    register #(.width(5)) rd_to_MEM(.clk(clk), .D(rd_EX), .Q(rd_MEM), .RAZ(kill_to_MEM));
    register #(.width(5)) rd_to_WB(.clk(clk), .D(rd_MEM), .Q(rd_WB), .RAZ(kill_to_WB));

    //Value of opcode and op must follow the instruction from ID to
    //WB. It does not have to return to EX for writing in rd, as
    //rd is set to 0 by the decoder if the instruction does not have
    //any writeback.
    logic[6:0] opcode_ID;
    //ID gives the opcode to IF and EX (jump instructions)
    logic[6:0] opcode_IFEX;
    logic[6:0] opcode_MEM;
    logic[6:0] opcode_WB;
    register #(.width(7)) opcode_to_IFEX(.clk(clk), .D(opcode_ID), .Q(opcode_IFEX), .RAZ(kill_to_EX));
    register #(.width(7)) opcode_to_MEM(.clk(clk), .D(opcode_IFEX), .Q(opcode_MEM), .RAZ(kill_to_MEM));
    register #(.width(7)) opcode_to_WB(.clk(clk), .D(opcode_MEM), .Q(opcode_WB), .RAZ(kill_to_WB));
    
    logic[3:0] op_ID;
    logic[3:0] op_EX;
    logic[3:0] op_MEM;
    logic[3:0] op_WB;
    register #(.width(4)) op_to_EX(.clk(clk), .D(op_ID), .Q(op_EX), .RAZ(kill_to_EX));
    register #(.width(4)) op_to_MEM(.clk(clk), .D(op_EX), .Q(op_MEM), .RAZ(kill_to_MEM));
    register #(.width(4)) op_to_WB(.clk(clk), .D(op_MEM), .Q(op_WB), .RAZ(kill_to_WB));

    //Value of rs1, rs2, imm must be driven from ID to EX
    logic[4:0] rs1_ID;
    logic[4:0] rs1_EX;
    register #(.width(5)) rs1_to_EX(.clk(clk), .D(rs1_ID), .Q(rs1_EX), .RAZ(kill_to_EX));

    logic[4:0] rs2_ID;
    logic[4:0] rs2_EX;
    register #(.width(5)) rs2_to_EX(.clk(clk), .D(rs2_ID), .Q(rs2_EX), .RAZ(kill_to_EX));
   
    //The immediate is also passed to IF for jump instructions
    logic[31:0] imm_ID;
    logic[31:0] imm_IFEX;
    register #(.width(32)) imm_to_IFEX(.clk(clk), .D(imm_ID), .Q(imm_IFEX), .RAZ(kill_to_EX));


    //Value of x2 (value of register r2)
    //must be driven from EX to MEM
    logic[31:0] x2_EX;
    logic[31:0] x2_MEM;
    register #(.width(32)) x2_to_MEM(.clk(clk), .D(x2_EX), .Q(x2_MEM), .RAZ(kill_to_MEM));

    //res is passed from EX to WB. The passage from EX to IF is
    //asynchronous
    logic[31:0] res_EX;
    logic[31:0] res_MEM;
    logic[31:0] res_WB;
    register #(.width(32)) res_to_MEM(.clk(clk), .D(res_EX), .Q(res_MEM), .RAZ(kill_to_MEM));
    register #(.width(32)) res_to_WB(.clk(clk), .D(res_MEM), .Q(res_WB), .RAZ(kill_to_WB));


    wire [31:0] jump_addr = (opcode == JALR) ? res_EX : PC_EX + imm_IFEX;
    wire jump = (
        opcode_IFEX == AUIPC 
     || opcode_IFEX == JAL
     || opcode_IFEX == JALR
     ||(opcode_IFEX == BRANCH && res_EX[0]));




    //The IF module is composed of a Program Counter, which output
    //is given the ROM and propagated to ID
    //logic[31:0] IF_out; obsolete, was redundant with PC_IF
    IF IF_module    (
            .clk(clk),
            .reset_n(reset_n),
            .jump(jump),
            .jumpaddr(jump_addr),
            .i_addr(PC_IF)
    );

    always @(*)
        begin
            i_address <= PC_IF;
        end

    //The ID module is composed of an asynchronous decoder
    ID ID_module    (
            .instr(i_data_read),
            
            .rs1(rs1_ID),
            .rs2(rs2_ID),
            .rd(rd_ID),
            .imm(imm_ID),
            .opcode(opcode_ID),
            .op(op_ID),
            .ill(ill_ID)
    );

    //The EX module is composed of a Register Bench and an ALU
    logic[31:0] xd_WB;
    EX EX_module    (
            .rs1(rs1_EX),
            .rs2(rs2_EX),
            .rs1_value(rs1_value_EX),
            .rs2_value(rs2_value_EX),
            .rd_WB(rd_WB),
            .rd_MEM(rd_MEM),
            .res_MEM(res_MEM),
            .res_WB(xd_WB),
            .imm(imm_IFEX),
            .op_EX(op_EX),
            .opcode_EX(opcode_IFEX),

            .res(res_EX),
            .x2_EX(x2_EX)
    );

    assign kill_to_EX = jump || trap;

    //The MEM module is mostly linking signals
    MEM MEM_module  (
            .x2(x2_MEM),
            .res(res_MEM),
            .opcode(opcode_MEM),
            
            .d_data_write(d_data_write),
            .d_address(d_address),
            .d_write_enable(d_write_enable)
    );

    //The WB module is mostly a multiplexer for knowing what to 
    //write in rd.
    WB WB_module    (
            .d_data_read(d_data_read),
            .res(res_WB),
            .PC(PC_WB),
            .opcode(opcode_WB),

            .xd(xd_WB)
    );


`ifdef RVFI_TRACE
    logic [63:0] ins_order;

    always_ff @(posedge clk) begin
        if(!reset_n)
            ins_order <= 0;
        else begin
            if(rvfi_valid)
                ins_order <= ins_order + 64'h1;
        end
    end

    assign rvfi_valid     <= !kill_to_EX;
    assign rvfi_order     <= order;
    assign rvfi_insn      <= // ???
    assign rvfi_trap      <= trap;
    assign rvfi_halt      <= trap;
    assign rvfi_intr      <= 0; // no trap handler
    assign rvfi_mode      <= 1;
    assign rvfi_ixl       <= 0;
    assign rvfi_rs1_addr  <= rs1_EX;
    assign rvfi_rs2_addr  <= rs2_EX;
    assign rvfi_rs1_rdata <= rs1_value_EX;
    assign rvfi_rs2_rdata <= rs2_value_EX;
    assign rvfi_rd_addr   <= rd_EX;
    assign rvfi_rd_wdata  <= res_EX;
    assign rvfi_pc_rdata  <= PC_EX;
    assign rvfi_pc_wdata  <= jump ? jump_addr : PC_ID;
    assign rvfi_mem_addr  <= d_address;
    assign rvfi_mem_rmask <= (!d_write_enable & d_data_valid) ? 4'hf : 4'h0;
    assign rvfi_mem_wmask <= ( d_write_enable & d_data_valid) ? 4'hf : 4'h0; 
    assign rvfi_mem_rdata <= d_data_read;
    assign rvfi_mem_wdata <= d_data_write;

`endif

endmodule
