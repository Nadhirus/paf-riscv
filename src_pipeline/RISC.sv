module RISC #(
        localparam NRET = 1,
        localparam ILEN = 32,
        localparam XLEN = 32
    ) (
    input logic            clk,
    input logic            reset_n,
    
    // RAM contenant les données
    output logic [31:0] d_address,
    input logic [31:0]  d_data_read,
    output logic [31:0] d_data_write,
    output logic [ 3:0] d_data_wstrb,
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
    output [NRET * XLEN   - 1 : 0] rvfi_mem_wdata,


    output [NRET * 64   - 1 : 0] rvfi_csr_minstret_wdata,
    output [NRET * 64   - 1 : 0] rvfi_csr_minstret_wmask,
    output [NRET * 64   - 1 : 0] rvfi_csr_minstret_rmask,
    output [NRET * 64   - 1 : 0] rvfi_csr_minstret_rdata,
    output [NRET * 64   - 1 : 0] rvfi_csr_mcycle_wdata,
    output [NRET * 64   - 1 : 0] rvfi_csr_mcycle_wmask,
    output [NRET * 64   - 1 : 0] rvfi_csr_mcycle_rmask,
    output [NRET * 64   - 1 : 0] rvfi_csr_mcycle_rdata
    `endif
    );
localparam LUI      = 7'b0110111;
localparam AUIPC    = 7'b0010111;
localparam JAL      = 7'b1101111;
localparam JALR     = 7'b1100111;

localparam BRANCH   = 7'b1100011;
localparam LOAD     = 7'b0000011;
localparam STORE    = 7'b0100011;
localparam IMM_OP   = 7'b0010011;
localparam REG_OP   = 7'b0110011;


    //KILL signals for setting internal registers to 0 and create
    //bubble.
    logic kill_to_EX;
    wire ex_stall;
    wire ext_ex_stall;
    wire stall_req_EX;

    wire ill_ID;
    logic ill_EX;

    wire trap_EX;

    logic trap;

    wire trap_trigger_EX = (ill_EX || trap_EX) && !ex_stall && !kill_to_EX_q;

    always_ff @(posedge clk) begin
        if(!reset_n)
            trap <= 0;
        else begin
            if(trap_trigger_EX)
                trap <= 1;
        end
    end

    //Value of PC must be propagated from IF module all the way to WB module
    logic[31:0] PC_IF;
    logic[31:0] PC_ID;
    logic[31:0] PC_EX;
    logic[31:0] PC_MEM;
    logic[31:0] PC_WB;

    //Value of rd must be propagated follow the instruction from
    //ID to WB and then return to EX.
    logic[4:0] rd_ID;
    logic[4:0] rd_EX;
    logic[4:0] rd_MEM;
    logic[4:0] rd_WB;


    //Value of opcode and op must follow the instruction from ID to
    //WB. It does not have to return to EX for writing in rd, as
    //rd is set to 0 by the decoder if the instruction does not have
    //any writeback.
    logic[6:0] opcode_ID;
    logic[6:0] opcode_EX;
    logic[6:0] opcode_MEM;
    logic[6:0] opcode_WB;

    logic[5:0] op_ID;
    logic[5:0] op_EX;
    
    wire [1:0] barrel_shift_ID;
    logic[1:0] barrel_shift_EX;

    // LW, LH, LB signals
    wire [1:0] ldsz_ID;
    wire       ldsx_ID;

    wire  [1:0] ldshift_EX;
    logic [1:0] ldsz_EX;
    logic       ldsx_EX;

    logic [1:0] ldshift_MEM;
    logic [1:0] ldsz_MEM;
    logic       ldsx_MEM;

    logic [1:0] ldshift_WB;
    logic [1:0] ldsz_WB;
    logic       ldsx_WB;
    


    always @(posedge clk) begin
        if(!reset_n) begin
            PC_ID  <= '0;
            {ill_EX, opcode_EX, PC_EX,  rd_EX}  <= '0;
            {opcode_MEM, PC_MEM, rd_MEM} <= '0;
            {opcode_WB, PC_WB,  rd_WB}  <= '0;
            {ldsz_EX, ldsx_EX}     <= '0;
            {ldshift_MEM, ldsz_MEM, ldsx_MEM}  <= '0;
            {ldshift_WB, ldsz_WB, ldsx_WB}     <= '0;

        end else begin
            if(!ex_stall) begin
                PC_ID <= PC_IF;


                {ldsz_EX, ldsx_EX}     <= {ldsz_ID, ldsx_ID};

                if(kill_to_EX)
                    {barrel_shift_EX, ill_EX, opcode_EX, op_EX, PC_EX, rd_EX}  <= '0;
                else
                    {barrel_shift_EX, ill_EX, opcode_EX, op_EX, PC_EX, rd_EX} 
                 <= {barrel_shift_ID, ill_ID, opcode_ID, op_ID, PC_ID, rd_ID};

                {opcode_MEM, PC_MEM, rd_MEM} <= {opcode_EX, PC_EX,  rd_EX};
            end
            else
                {opcode_MEM, PC_MEM, rd_MEM} <= '0;


            {ldshift_MEM, ldsz_MEM, ldsx_MEM}  <= {ldshift_EX, ldsz_EX, ldsx_EX};
            {ldshift_WB, ldsz_WB, ldsx_WB}     <= {ldshift_MEM, ldsz_MEM, ldsx_MEM};

            {opcode_WB, PC_WB,  rd_WB}  <= {opcode_MEM, PC_MEM, rd_MEM};
        end
    end




    //Value of rs1, rs2, imm must be driven from ID to EX
    logic[4:0] rs1_ID;
    logic[4:0] rs1_EX;

    wire [31:0] rs1_value_EX;
    wire [31:0] rs2_value_EX;

    logic[4:0] rs2_ID;
    logic[4:0] rs2_EX;
    //The immediate is also passed to IF for jump instructions
    logic[31:0] imm_ID;
    logic[31:0] imm_IFEX;


    //Value of x2 (value of register r2)
    //must be driven from EX to MEM
    logic[31:0] x2_EX;
    logic[31:0] x2_MEM;

    //res is passed from EX to WB. The passage from EX to IF is
    //asynchronous
    logic[31:0] res_EX;
    logic[31:0] res_MEM;
    logic[31:0] res_WB;


    always @(posedge clk) begin
        if(!reset_n) begin
            rs1_EX  <= '0;
            rs2_EX  <= '0;
            imm_IFEX<= '0;
            x2_MEM  <= '0;
            res_MEM <= '0;
            res_WB <= '0;
        end else begin
            if(kill_to_EX)
                {rs1_EX, rs2_EX, imm_IFEX} <= '0;
            else if(!ex_stall) begin
                rs1_EX   <= rs1_ID;
                rs2_EX   <= rs2_ID;
                imm_IFEX <= imm_ID;
            end


            if(!ex_stall)
            {x2_MEM, res_MEM} <= {x2_EX, res_EX};
            else
                {x2_MEM, res_MEM} <= '0;

            res_WB  <= res_MEM;
        end
    end


    wire [31:0] jump_addr_EX;
    wire jump_EX;
    
    assign jump_addr_EX = (opcode_EX == JALR) ? res_EX : PC_EX + imm_IFEX;

    assign jump_EX = !ex_stall && !trap && (
       opcode_EX == JAL
     || opcode_EX == JALR
     ||(opcode_EX == BRANCH && res_EX[0]));



    logic ex_stall_q;

    always @(posedge clk) begin
        if(!reset_n)
            ex_stall_q <= '0;
        else
            ex_stall_q <= ex_stall;
    end

    // stall IF-ID-EX stage if a memory access is succeded by an instruction
    // that uses the memory result 
    // or if the execute stage takes more than one cycle
    assign ext_ex_stall = (opcode_MEM == LOAD) && (rs1_EX == rd_MEM || rs2_EX == rd_MEM);
    assign ex_stall = stall_req_EX || ext_ex_stall;





    assign kill_to_EX = jump_EX || trap || trap_trigger_EX;





    //The IF module is composed of a Program Counter, which output
    //is given the ROM and propagated to ID
    //logic[31:0] IF_out; obsolete, was redundant with PC_IF
    IF IF_module    (
            .clk(clk),
            .reset_n(reset_n),
            .stall(ex_stall),
            .jump(jump_EX),
            .jumpaddr(jump_addr_EX),
            .i_addr(PC_IF)
    );

    assign i_address = PC_IF;




    //The ID module is composed of an asynchronous decoder
    ID ID_module    (
            .instr(i_data_read),
            
            .rs1(rs1_ID),
            .rs2(rs2_ID),
            .rd(rd_ID),
            .imm(imm_ID),
            .opcode(opcode_ID),
            .op(op_ID),
            .barrel_shift(barrel_shift_ID),
            .ldsz(ldsz_ID), 
            .ldsx(ldsx_ID),
            .ill(ill_ID)
    );

    //The EX module is composed of a Register Bench and an ALU
    logic[31:0] xd_WB;
    EX EX_module    (
            .clk(clk),
            .reset_n(reset_n),
            .rs1(rs1_EX),
            .rs2(rs2_EX),
            .rs1_value(rs1_value_EX),
            .rs2_value(rs2_value_EX),
            .ext_stall(ext_ex_stall),
            .barrel_shift(barrel_shift_EX),
            .rd_WB(rd_WB),
            .rd_MEM(rd_MEM),
            .res_MEM(res_MEM),
            .res_WB(xd_WB),
            .imm(imm_IFEX),
            .op_EX(op_EX),
            .opcode_EX(opcode_EX),
            .PC(PC_EX),
            .ldsz(ldsz_EX), 
            .ldshift(ldshift_EX),


            .res(res_EX),
            .x2_EX(x2_EX),

            .stall_req(stall_req_EX),
            .trap(trap_EX)
    );


    //The MEM module is mostly linking signals
    MEM MEM_module  (
            .x2(x2_MEM),
            .res(res_MEM),
            .opcode(opcode_MEM),
            .load_shift(ldshift_MEM),
            
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
            .load_shift(ldshift_WB),
            .load_size(ldsz_WB),
            .load_sign_extend(ldsx_WB),

            .xd(xd_WB)
    );


`ifdef RVFI_TRACE
    logic [63:0] ins_order;

    logic kill_to_EX_q;

    always_ff @(posedge clk) begin
        if(!reset_n)
            kill_to_EX_q <= '0;
        else
            kill_to_EX_q <= kill_to_EX;
    end

    

    wire ins_trap = trap_trigger_EX;


    //wire pre_ins_valid = !kill_to_EX && !ex_stall;
    wire ins_valid = 
            !kill_to_EX_q && ((!trap || ins_trap) && !ex_stall) && (opcode_EX != 0 || ill_EX);



    wire  [63:0] next_ins_order = (ins_valid) ? (ins_order + 64'h1) : ins_order;
    //wire  [63:0] next_ins_order = ins_order + 64'h1;

    always_ff @(posedge clk) begin
        if(!reset_n)
            ins_order <= 0;
        else
            ins_order <= next_ins_order;
    end

    
    wire [31:0] pc_wdata = jump_EX ? jump_addr_EX : PC_ID;



    logic        valid_q;
    logic        trap_q;
    logic [31:0] mem_addr_q;
    logic [3:0]  mem_wmask_q;
    logic [31:0] mem_wdata_q;
    logic [31:0] pc_wdata_q;
    logic [31:0] rs1_rdata_q;
    logic [31:0] rs2_rdata_q;
    logic [4:0]  rs1_q;
    logic [4:0]  rs2_q;
    logic [63:0] ins_order_q;

    wire  [31:0] insn_ID = i_data_read;
    logic [31:0] insn_EX;
    logic [31:0] insn_EX_q;

    logic [6:0]  opcode_EX_q;
    logic [4:0]  rd_q;
    logic [31:0] res_q;

    logic        valid_q2;
    logic        trap_q2;
    logic [31:0] pc_wdata_q2;
    logic [31:0] rs1_rdata_q2;
    logic [31:0] rs2_rdata_q2;
    logic [4:0] rs1_q2;
    logic [4:0] rs2_q2;
    logic [31:0] insn_EX2;
    logic [31:0] insn_EX_q2;
    logic [6:0] opcode_EX_q2;
    logic [4:0] rd_q2;
    logic [31:0] res_q2;

    logic [31:0] pc_EX_q;
    logic [31:0] pc_EX_q2;
    

// 00 -> 0001
// 01 -> 0011
// 11 -> 1111
    wire [3:0] load_mask = {ldsz_WB[1], ldsz_WB[1], ldsz_WB[0], 1'b1};
    wire [3:0] store_mask= {ldsz_MEM[1], ldsz_MEM[1], ldsz_MEM[0], 1'b1};


    wire [3:0] mem_rmask = (opcode_WB == LOAD) ? load_mask << ldshift_WB : 0;

    assign d_data_wstrb = (opcode_MEM == STORE) ? store_mask << ldshift_MEM : 0;


    always_ff @(posedge clk) begin
        if(!reset_n) begin
            valid_q      <= '0;
            trap_q       <= '0;
            mem_addr_q   <= '0;
            mem_wmask_q  <= '0;
            mem_wdata_q  <= '0;
            pc_wdata_q   <= '0;
            rs1_rdata_q  <= '0;
            rs2_rdata_q  <= '0;
            rs1_q        <= '0;
            rs2_q        <= '0;
            insn_EX      <= '0;
            insn_EX_q    <= '0;
            opcode_EX_q  <= '0;
            ins_order_q  <= '0;
            rd_q         <= '0;
            res_q        <= '0;
            pc_EX_q      <= '0;
            valid_q2     <= '0;
            trap_q2      <= '0;
            pc_wdata_q2  <= '0;
            rs1_rdata_q2 <= '0;
            rs2_rdata_q2 <= '0;
            rs1_q2       <= '0;
            rs2_q2       <= '0;
            insn_EX2     <= '0;
            insn_EX_q2   <= '0;
            opcode_EX_q2 <= '0;
            rd_q2        <= '0;
            res_q2       <= '0;
            pc_EX_q2     <= '0;
        end
        else  begin
            ins_order_q  <= ins_order;
            valid_q2     <= valid_q;
            trap_q2      <= trap_q;
            pc_wdata_q2  <= pc_wdata_q;
            rs1_rdata_q2 <= rs1_rdata_q;
            rs2_rdata_q2 <= rs2_rdata_q;
            rs1_q2       <= rs1_q;
            rs2_q2       <= rs2_q;
            insn_EX2     <= insn_EX;
            insn_EX_q2   <= insn_EX_q;
            opcode_EX_q2 <= opcode_EX_q;
            rd_q2        <= rd_q;
            res_q2       <= res_q;
            pc_EX_q2     <= pc_EX_q;

            valid_q     <= ins_valid;
            trap_q      <= ins_trap;
            mem_addr_q  <= d_address;
            mem_wmask_q <= d_data_wstrb;
            mem_wdata_q <= d_data_write;
            pc_wdata_q  <= pc_wdata;
            rs1_rdata_q <= rs1_value_EX;
            rs2_rdata_q <= rs2_value_EX;
            rs1_q       <= rs1_EX;
            rs2_q       <= rs2_EX;
            opcode_EX_q <= opcode_EX;

            pc_EX_q <= PC_EX;

            rd_q <= rd_EX;
            res_q <= res_EX;

            if(!ex_stall) begin
                insn_EX     <= insn_ID;
            end

            insn_EX_q    <= insn_EX;
        end
    end

    wire [31:0] rd_wdata = xd_WB;

    assign rvfi_valid     = valid_q2;
    assign rvfi_order     = ins_order_q;
    assign rvfi_insn      = insn_EX_q2;
    assign rvfi_trap      = trap_q2;
    assign rvfi_halt      = trap_q2;
    assign rvfi_intr      = 0; // no trap handler
    assign rvfi_mode      = 1;
    assign rvfi_ixl       = 0;
    assign rvfi_rs1_addr  = rs1_q2;
    assign rvfi_rs2_addr  = rs2_q2;
    
    assign rvfi_rd_addr   = (opcode_EX_q2 == BRANCH || opcode_EX_q2 == STORE) ? 0 : rd_q2;
    assign rvfi_mem_addr  = mem_addr_q;
    assign rvfi_mem_rdata = d_data_read;
    assign rvfi_mem_rmask = mem_rmask;
    assign rvfi_mem_wdata = mem_wdata_q;
    assign rvfi_mem_wmask = mem_wmask_q; 

    assign rvfi_pc_wdata  = pc_wdata_q2;
    assign rvfi_pc_rdata  = pc_EX_q2;
    assign rvfi_rd_wdata  = (rvfi_rd_addr == 0) ? 0 : rd_wdata;
    assign rvfi_rs1_rdata = rs1_rdata_q2;
    assign rvfi_rs2_rdata = rs2_rdata_q2;

    assign rvfi_csr_minstret_wdata = '0;
    assign rvfi_csr_minstret_wmask = '0;
    assign rvfi_csr_minstret_rmask = '0;
    assign rvfi_csr_minstret_rdata = '0;
    assign rvfi_csr_mcycle_wdata   = '0;
    assign rvfi_csr_mcycle_wmask   = '0;
    assign rvfi_csr_mcycle_rmask   = '0;
    assign rvfi_csr_mcycle_rdata   = '0;
`endif

endmodule
