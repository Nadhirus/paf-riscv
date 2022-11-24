`ifndef OPTYPE
localparam LUI      = 7'b0110111;
localparam AUIPC    = 7'b0010111;
localparam JAL      = 7'b1101111;
localparam JALR     = 7'b1100111;

localparam BRANCH   = 7'b1100011;
localparam LOAD     = 7'b0000011;
localparam STORE    = 7'b0100011;
localparam IMM_OP   = 7'b0010011;
localparam REG_OP   = 7'b0110011;
`define OPTYPE
`endif

