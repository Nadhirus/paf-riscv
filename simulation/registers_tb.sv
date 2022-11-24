module registers_tb();

    logic[4:0] rs1;
    logic[4:0] rs2;
    logic[4:0]  rd;
    logic[31:0] xd;
    logic    rd_en;
    logic[31:0] x1;
    logic[31:0] x2;
    
    registers registers_test(.rs1(rs1), .rs2(rs2), .rd(rd), .xd(xd), .rd_en(rd_en), .x1(x1), .x2(x2));


    initial begin
        rs1 <= 5'd0;
        rs2 <= 5'd0;
        rd <= 5'd0;
        xd <= 32'd0;
        rd_en <= 1'b0;
        
        #1ns

        rd <= 5'd0;
        xd <= 32'hc0ca_c01a;
        rd_en <= 1'b1;

        #1ns

        rd <= 5'd1;
        xd <= 32'hc0ca_c01a;
        rd_en <= 1'b1;

        #1ns

        rd <= 5'd2;
        xd <= 32'hdede_2222;
        rd_en <= 1'b1;

        #1ns

        rs1 <= 5'd1;
        rs2 <= 5'd2;
        rd <= 5'd3;
        xd <= 32'hcaca_c01a;
        rd_en <= 1'b0;


    end

endmodule