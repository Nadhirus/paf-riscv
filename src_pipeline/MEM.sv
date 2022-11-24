module MEM  (
        input logic[31:0] x2,
        input logic[31:0] res,
        input logic[6:0] opcode,

        output logic[31:0] d_data_write,
        output logic[31:0] d_address,
        output logic d_write_enable
    );

    `include "OPTYPE.vh"

    always @(*) begin
        d_data_write <= x2;
        d_address <= res;
        d_write_enable <= (opcode == STORE);
    end

endmodule
