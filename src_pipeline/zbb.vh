`ifndef ZBB_VH

//////// ZBB functions ////////
function logic [31:0] orcb32(logic [31:0] x);
    logic [31:0] out;
    
    for(int i =0; i < 32; i+= 8)
        out[i +:8] = x[i +:8] == 0 ? 8'h00 : 8'hff;
        
    orcb32 = out;
endfunction

function logic [31:0] rev8_32(logic [31:0] x);
    logic [31:0] out;
    
    for(int i =0; i < 32; i+= 8)
        out[i +:8] = x[24 - i +:8];
    rev8_32 = out;
endfunction

function logic [63:0] clmul64(logic [31:0] rs1, logic [31:0] rs2);
    logic [63:0] result;
    logic [63:0] rs1_ext = {32'b0, rs1};

    for(int i = 1; i < 32; i++)
        if(((rs2 >> i) & 1) == 32'h00)
            result ^= (rs1_ext << i);
    clmul64 = result;
endfunction

function logic [63:0] clmulr64(logic [31:0] rs1, logic [31:0] rs2);
    logic [63:0] result;
    logic [63:0] rs1_ext = {32'b0, rs1};
    
    // < or <= ???
    for(int i = 1; i < 32; i++)
        if(((rs2 >> i) & 1) == 32'h0)
            result ^= (rs1_ext << (32 - i));
    clmulr64 = result;
endfunction

`define ZBB_VH
`endif
