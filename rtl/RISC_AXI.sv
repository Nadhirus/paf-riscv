module RISC_axi 
#(
// pour le moment je l'ai mis ici mais normalement on dois le mettre dans les OPTYPES.vh
parameter NUM_CORES = 4, 
parameter MASTER_ID_WIDTH = $clog2(NUM_CORES)
)
(
    input logic            clk,
    input logic            reset_n,

    // AXI4-Lite Master Interface
    // Write Address Channel
    output logic [31:0]    m_axi_awaddr,
    output logic [2:0]     m_axi_awprot,
    output logic           m_axi_awvalid,
    input  logic           m_axi_awready,

    // Write Data Channel
    output logic [31:0]    m_axi_wdata,
    output logic [3:0]     m_axi_wstrb,
    output logic           m_axi_wvalid,
    input  logic           m_axi_wready,

    // Write Response Channel
    input  logic [1:0]     m_axi_bresp,
    input  logic           m_axi_bvalid,
    output logic           m_axi_bready,

    // Read Address Channel
    output logic [31:0]    m_axi_araddr,
    output logic [2:0]     m_axi_arprot,
    output logic           m_axi_arvalid,
    input  logic           m_axi_arready,

    // Read Data Channel
    input  logic [31:0]    m_axi_rdata,
    input  logic [1:0]     m_axi_rresp,
    input  logic           m_axi_rvalid,
    output logic           m_axi_rready,

    // LR/SC signals 
  //  0 = normal, 1 = load-reserve (LR), 2 = store-conditional (SC)
  input  logic [1:0]                   axi_exclusive_op,
  // Master identifier (assume one reservation set per core)
  input  logic [MASTER_ID_WIDTH-1:0]     axi_master_id
    `ifdef RVFI_TRACE
    ,
    // RVFI Trace Signals
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
    output [NRET * 64     - 1 : 0] rvfi_csr_minstret_wdata,
    output [NRET * 64     - 1 : 0] rvfi_csr_minstret_wmask,
    output [NRET * 64     - 1 : 0] rvfi_csr_minstret_rmask,
    output [NRET * 64     - 1 : 0] rvfi_csr_minstret_rdata,
    output [NRET * 64     - 1 : 0] rvfi_csr_mcycle_wdata,
    output [NRET * 64     - 1 : 0] rvfi_csr_mcycle_wmask,
    output [NRET * 64     - 1 : 0] rvfi_csr_mcycle_rmask,
    output [NRET * 64     - 1 : 0] rvfi_csr_mcycle_rdata
    `endif
);

    localparam NRET = 1;
    localparam ILEN = 32;
    localparam XLEN = 32;

    // Internal signals for RISC core interface
    logic [31:0] d_address;
    logic [31:0] d_data_read;
    logic [31:0] d_data_write;
    logic [3:0]  d_data_wstrb;
    logic        d_write_enable;
    logic        d_data_valid;

    logic [31:0] i_address;
    logic [31:0] i_data_read;
    logic        i_data_valid;

    // Instantiate the RISC core
    RISC risc_core (
        .clk(clk),
        .reset_n(reset_n),
        .d_address(d_address),
        .d_data_read(d_data_read),
        .d_data_write(d_data_write),
        .d_data_wstrb(d_data_wstrb),
        .d_write_enable(d_write_enable),
        .d_data_valid(d_data_valid),
        .i_address(i_address),
        .i_data_read(i_data_read),
        .i_data_valid(i_data_valid)
        `ifdef RVFI_TRACE
        ,
        .rvfi_valid(rvfi_valid),
        .rvfi_order(rvfi_order),
        .rvfi_insn(rvfi_insn),
        .rvfi_trap(rvfi_trap),
        .rvfi_halt(rvfi_halt),
        .rvfi_intr(rvfi_intr),
        .rvfi_mode(rvfi_mode),
        .rvfi_ixl(rvfi_ixl),
        .rvfi_rs1_addr(rvfi_rs1_addr),
        .rvfi_rs2_addr(rvfi_rs2_addr),
        .rvfi_rs1_rdata(rvfi_rs1_rdata),
        .rvfi_rs2_rdata(rvfi_rs2_rdata),
        .rvfi_rd_addr(rvfi_rd_addr),
        .rvfi_rd_wdata(rvfi_rd_wdata),
        .rvfi_pc_rdata(rvfi_pc_rdata),
        .rvfi_pc_wdata(rvfi_pc_wdata),
        .rvfi_mem_addr(rvfi_mem_addr),
        .rvfi_mem_rmask(rvfi_mem_rmask),
        .rvfi_mem_wmask(rvfi_mem_wmask),
        .rvfi_mem_rdata(rvfi_mem_rdata),
        .rvfi_mem_wdata(rvfi_mem_wdata),
        .rvfi_csr_minstret_wdata(rvfi_csr_minstret_wdata),
        .rvfi_csr_minstret_wmask(rvfi_csr_minstret_wmask),
        .rvfi_csr_minstret_rmask(rvfi_csr_minstret_rmask),
        .rvfi_csr_minstret_rdata(rvfi_csr_minstret_rdata),
        .rvfi_csr_mcycle_wdata(rvfi_csr_mcycle_wdata),
        .rvfi_csr_mcycle_wmask(rvfi_csr_mcycle_wmask),
        .rvfi_csr_mcycle_rmask(rvfi_csr_mcycle_rmask),
        .rvfi_csr_mcycle_rdata(rvfi_csr_mcycle_rdata)
        `endif
    );

    // State machines for AXI transactions
    typedef enum logic [1:0] {
        I_IDLE,
        I_SEND_AR,
        I_WAIT_R
    } i_state_t;

    typedef enum logic [1:0] {
        DR_IDLE,
        DR_SEND_AR,
        DR_WAIT_R
    } dr_state_t;

    typedef enum logic [2:0] {
        DW_IDLE,
        DW_SEND_AW,
        DW_SEND_W,
        DW_WAIT_B
    } dw_state_t;

    i_state_t i_state = I_IDLE;
    dr_state_t dr_state = DR_IDLE;
    dw_state_t dw_state = DW_IDLE;

    logic [31:0] saved_i_addr;
    logic [31:0] saved_dr_addr;
    logic [31:0] saved_dw_addr;
    logic [31:0] saved_dw_data;
    logic [3:0]  saved_dw_strb;

    logic read_pending = 0; // 0: instruction, 1: data

    // AXI signal assignments
    assign m_axi_awprot = 3'b000;
    assign m_axi_arprot = 3'b000;

    // Instruction Fetch State Machine
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            i_state <= I_IDLE;
            m_axi_arvalid <= 0;
            saved_i_addr <= 0;
            i_data_valid <= 0;
            i_data_read <= 0;
        end else begin
            case (i_state)
                I_IDLE: begin
                    if (i_address != saved_i_addr) begin
                        saved_i_addr <= i_address;
                        m_axi_araddr <= i_address;
                        m_axi_arvalid <= 1;
                        i_state <= I_SEND_AR;
                    end
                end
                I_SEND_AR: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 0;
                        read_pending <= 0;
                        i_state <= I_WAIT_R;
                    end
                end
                I_WAIT_R: begin
                    if (m_axi_rvalid && !read_pending) begin
                        i_data_read <= m_axi_rdata;
                        i_data_valid <= 1;
                        saved_i_addr <= i_address; // Update to current address
                        i_state <= I_IDLE;
                    end
                end
            endcase
        end
    end

    // Data Read State Machine
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dr_state <= DR_IDLE;
            m_axi_arvalid <= 0;
            saved_dr_addr <= 0;
            d_data_valid <= 0;
            d_data_read <= 0;
        end else begin
            case (dr_state)
                DR_IDLE: begin
                    if (!d_write_enable && (d_address != saved_dr_addr)) begin
                        saved_dr_addr <= d_address;
                        m_axi_araddr <= d_address;
                        m_axi_arvalid <= 1;
                        dr_state <= DR_SEND_AR;
                    end
                end
                DR_SEND_AR: begin
                    if (m_axi_arready) begin
                        m_axi_arvalid <= 0;
                        read_pending <= 1;
                        dr_state <= DR_WAIT_R;
                    end
                end
                DR_WAIT_R: begin
                    if (m_axi_rvalid && read_pending) begin
                        d_data_read <= m_axi_rdata;
                        d_data_valid <= 1;
                        saved_dr_addr <= d_address; // Update to current address
                        dr_state <= DR_IDLE;
                    end
                end
            endcase
        end
    end

    // Data Write State Machine
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            dw_state <= DW_IDLE;
            m_axi_awvalid <= 0;
            m_axi_wvalid <= 0;
            m_axi_bready <= 0;
            saved_dw_addr <= 0;
            saved_dw_data <= 0;
            saved_dw_strb <= 0;
        end else begin
            case (dw_state)
                DW_IDLE: begin
                    if (d_write_enable) begin
                        saved_dw_addr <= d_address;
                        saved_dw_data <= d_data_write;
                        saved_dw_strb <= d_data_wstrb;
                        m_axi_awaddr <= d_address;
                        m_axi_awvalid <= 1;
                        m_axi_wdata <= d_data_write;
                        m_axi_wstrb <= d_data_wstrb;
                        m_axi_wvalid <= 1;
                        dw_state <= DW_SEND_AW;
                    end
                end
                DW_SEND_AW: begin
                    if (m_axi_awready) begin
                        m_axi_awvalid <= 0;
                        if (m_axi_wready) begin
                            m_axi_wvalid <= 0;
                            dw_state <= DW_WAIT_B;
                        end else begin
                            dw_state <= DW_SEND_W;
                        end
                    end else if (m_axi_wready) begin
                        m_axi_wvalid <= 0;
                        dw_state <= DW_SEND_AW;
                    end
                end
                DW_SEND_W: begin
                    if (m_axi_wready) begin
                        m_axi_wvalid <= 0;
                        dw_state <= DW_WAIT_B;
                    end
                end
                DW_WAIT_B: begin
                    m_axi_bready <= 1;
                    if (m_axi_bvalid) begin
                        m_axi_bready <= 0;
                        dw_state <= DW_IDLE;
                    end
                end
            endcase
        end
    end

    // AXI Read Data Channel
    assign m_axi_rready = 1'b1; // Always ready to accept read data

endmodule