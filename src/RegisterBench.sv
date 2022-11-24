module RegisterBench    (   
                    input logic[4:0] rs1,
                    input logic[4:0] rs2,
                    input logic[4:0] rd,
                    input logic[31:0] xd,
                    input logic rd_en,

                    output logic[31:0] x1,
                    output logic[31:0] x2);

    logic[31:0] regs[31:0];

    initial begin
        regs[0] = 0;
    end

    always @(*)
        x1 <= regs[rs1];

    always @(*)
        x2 <= regs[rs2];

    always @(*)
        if(rd_en && rd != 5'd0)
            regs[rd] <= xd;

endmodule
