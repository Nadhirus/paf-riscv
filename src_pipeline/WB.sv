module WB   (
    input [31:0] d_data_read,
    input [31:0] res,
    input [31:0] PC,
    input [6:0] opcode,

    input [1:0] load_shift,
    input [1:0] load_size,
    input       load_sign_extend,

    output logic[31:0] xd
);

    `include "OPTYPE.vh"
                        // d_data_read >> (8 * load_shift)
    (* keep *) wire [31:0] load_val = d_data_read >> ({load_shift, 3'b000});
    (* keep *) wire [31:0] lw_val   = load_val;
    (* keep *) wire [15:0] lh_val   = load_val[15:0];
    (* keep *) wire [ 7:0] lb_val   = load_val[ 7:0];

    //If the operation is LOAD, the output will be d_data_read
    //If AUIPC, JAL, JALR, we save the pc + 4 in rd
    //Else res is returned, as rd = 0 if it is not necessary to have
    //a WB.
    always @(*)
        if (opcode == JAL || opcode == JALR)
            xd = PC + 32'd4;
        else if(opcode == LOAD) begin
            casez({load_sign_extend, load_size})
                3'b1_01: /* LH  */ xd = $signed(lh_val);
                3'b0_01: /* LHU */ xd = {16'h0, lh_val};
                3'b1_00: /* LB  */ xd = $signed(lb_val);
                3'b0_00: /* LBU */ xd = {24'h0, lb_val};
                3'bZ_11: /* LW  */ xd =         lw_val ;
                default: /* undefined */ xd =   lw_val ;
            endcase
        end
        else
            xd = res;

endmodule
