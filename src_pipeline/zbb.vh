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

`define ZBB_VH
`endif
