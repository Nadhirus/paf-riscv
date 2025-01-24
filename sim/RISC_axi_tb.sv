`timescale 1ns/1ps

module RISC_axi_tb;
    // System Signals
    logic clk;
    logic reset_n;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // AXI System Parameters
    localparam AXI_ADDR_WIDTH = 32;
    localparam AXI_DATA_WIDTH = 32;
    
    // Memory Mapping
    localparam ROM_BASE = 32'h0000_0000;
    localparam ROM_SIZE = 32'h0000_FFFF;
    localparam RAM_BASE = 32'h1000_0000;
    localparam RAM_SIZE = 32'h0000_FFFF;

    // AXI Signals
    // Write Address Channel
    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [2:0]                axi_awprot;
    logic                      axi_awvalid;
    logic                      axi_awready_rom, axi_awready_ram;
    logic                      axi_awready;
    
    // Write Data Channel
    logic [AXI_DATA_WIDTH-1:0] axi_wdata;
    logic [AXI_DATA_WIDTH/8-1:0] axi_wstrb;
    logic                      axi_wvalid;
    logic                      axi_wready_rom, axi_wready_ram;
    logic                      axi_wready;
    
    // Write Response Channel
    logic [1:0]                axi_bresp_rom, axi_bresp_ram;
    logic [1:0]                axi_bresp;
    logic                      axi_bvalid_rom, axi_bvalid_ram;
    logic                      axi_bvalid;
    logic                      axi_bready;
    
    // Read Address Channel
    logic [AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic [2:0]                axi_arprot;
    logic                      axi_arvalid;
    logic                      axi_arready_rom, axi_arready_ram;
    logic                      axi_arready;
    
    // Read Data Channel
    logic [AXI_DATA_WIDTH-1:0] axi_rdata_rom, axi_rdata_ram;
    logic [AXI_DATA_WIDTH-1:0] axi_rdata;
    logic [1:0]                axi_rresp_rom, axi_rresp_ram;
    logic [1:0]                axi_rresp;
    logic                      axi_rvalid_rom, axi_rvalid_ram;
    logic                      axi_rvalid;
    logic                      axi_rready;

    // Resolve shared signals
    assign axi_awready = axi_awready_rom | axi_awready_ram;
    assign axi_wready = axi_wready_rom | axi_wready_ram;
    assign axi_bresp = axi_bvalid_rom ? axi_bresp_rom : axi_bresp_ram;
    assign axi_bvalid = axi_bvalid_rom | axi_bvalid_ram;

    assign axi_arready = axi_arready_rom | axi_arready_ram;
    assign axi_rdata = axi_rvalid_rom ? axi_rdata_rom : axi_rdata_ram;
    assign axi_rresp = axi_rvalid_rom ? axi_rresp_rom : axi_rresp_ram;
    assign axi_rvalid = axi_rvalid_rom | axi_rvalid_ram;

    // Instantiate DUT
    RISC_axi risc_axi (
        .clk(clk),
        .reset_n(reset_n),
        .m_axi_awaddr(axi_awaddr),
        .m_axi_awprot(axi_awprot),
        .m_axi_awvalid(axi_awvalid),
        .m_axi_awready(axi_awready),
        .m_axi_wdata(axi_wdata),
        .m_axi_wstrb(axi_wstrb),
        .m_axi_wvalid(axi_wvalid),
        .m_axi_wready(axi_wready),
        .m_axi_bresp(axi_bresp),
        .m_axi_bvalid(axi_bvalid),
        .m_axi_bready(axi_bready),
        .m_axi_araddr(axi_araddr),
        .m_axi_arprot(axi_arprot),
        .m_axi_arvalid(axi_arvalid),
        .m_axi_arready(axi_arready),
        .m_axi_rdata(axi_rdata),
        .m_axi_rresp(axi_rresp),
        .m_axi_rvalid(axi_rvalid),
        .m_axi_rready(axi_rready)
    );

    // Instantiate ROM
    rom_axi #(
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .ADDR_WIDTH(16)  // 64KB ROM
    ) rom (
        .axi_aclk(clk),
        .axi_aresetn(reset_n),
        .axi_araddr(axi_araddr - ROM_BASE),
        .axi_arprot(axi_arprot),
        .axi_arvalid(axi_arvalid && (axi_araddr >= ROM_BASE) && (axi_araddr < (ROM_BASE + ROM_SIZE))),
        .axi_arready(axi_arready_rom),
        .axi_rdata(axi_rdata_rom),
        .axi_rresp(axi_rresp_rom),
        .axi_rvalid(axi_rvalid_rom),
        .axi_rready(axi_rready)
    );

    // Instantiate RAM
    ram_axi #(
        .DATA_WIDTH(AXI_DATA_WIDTH),
        .ADDR_WIDTH(16)  // 64KB RAM
    ) ram (
        .axi_aclk(clk),
        .axi_aresetn(reset_n),
        .axi_awaddr(axi_awaddr - RAM_BASE),
        .axi_awprot(axi_awprot),
        .axi_awvalid(axi_awvalid && (axi_awaddr >= RAM_BASE) && (axi_awaddr < (RAM_BASE + RAM_SIZE))),
        .axi_awready(axi_awready_ram),
        .axi_wdata(axi_wdata),
        .axi_wstrb(axi_wstrb),
        .axi_wvalid(axi_wvalid),
        .axi_wready(axi_wready_ram),
        .axi_bresp(axi_bresp_ram),
        .axi_bvalid(axi_bvalid_ram),
        .axi_bready(axi_bready),
        .axi_araddr(axi_araddr - RAM_BASE),
        .axi_arprot(axi_arprot),
        .axi_arvalid(axi_arvalid && (axi_araddr >= RAM_BASE) && (axi_araddr < (RAM_BASE + RAM_SIZE))),
        .axi_arready(axi_arready_ram),
        .axi_rdata(axi_rdata_ram),
        .axi_rresp(axi_rresp_ram),
        .axi_rvalid(axi_rvalid_ram),
        .axi_rready(axi_rready)
    );

    // Test Control
    initial begin
        reset_n = 0;
        $readmemh("C:/Users/Nadhir/Desktop/Projects/paf-riscv/paf-riscv/rom/rom_data.mem", rom.rom);

        #20 reset_n = 1;
        $display("Starting simulation...");

        #5000 $display("Simulation completed.");
    end

    // Monitoring
    always @(posedge clk) begin
        if (reset_n) begin
            if (axi_awvalid && axi_awready)
                $display("Write Address: 0x%h", axi_awaddr);
            if (axi_wvalid && axi_wready)
                $display("Write Data: 0x%h", axi_wdata);
            if (axi_arvalid && axi_arready)
                $display("Read Address: 0x%h", axi_araddr);
            if (axi_rvalid && axi_rready)
                $display("Read Data: 0x%h", axi_rdata);
        end
    end

endmodule
