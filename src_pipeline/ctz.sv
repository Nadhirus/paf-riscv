// single cycle trailing zeros counter
// if x=0, res = 32
module ctz(
    input  [31:0] x,
    output [ 5:0] res
);
// max: 32 = ctz(0x00000000)

logic [2:0] ctz0[0: 7]; // 0 -> 4
logic [3:0] ctz1[0: 3]; // 0 -> 8
logic [4:0] ctz2[0: 1]; // 0 -> 16
logic [5:0] ctz3;       // 0 -> 32


wire  [3:0] x_parts  [0:7];

generate
    genvar i;
    for(i = 0; i < 8; i++) begin:
        assign x_parts[i] = x[4 * i +:4];
    end
endgenerate

assign res = ctz3;

always_comb begin
    for(int i = 0; i < 8; i++)
        case(x_parts[i])
            // ctz[0] = !x[0] &  x[1]
            // ctz[1] = !x[0] & !x[1] & (x[2] | x[3])
            // ctz[2] = !x[0] & !x[1] & !x[2] & !x[3]
            4'b 0000: /* 4 */ ctz0[i] = 3'b 100;
            4'b 0001: /* 0 */ ctz0[i] = 3'b 000;
            4'b 0010: /* 1 */ ctz0[i] = 3'b 001;
            4'b 0011: /* 0 */ ctz0[i] = 3'b 000;
            4'b 0100: /* 2 */ ctz0[i] = 3'b 010;
            4'b 0101: /* 0 */ ctz0[i] = 3'b 000;
            4'b 0110: /* 1 */ ctz0[i] = 3'b 001;
            4'b 0111: /* 0 */ ctz0[i] = 3'b 000;
            4'b 1000: /* 3 */ ctz0[i] = 3'b 011;
            4'b 1001: /* 0 */ ctz0[i] = 3'b 000;
            4'b 1010: /* 1 */ ctz0[i] = 3'b 001;
            4'b 1011: /* 0 */ ctz0[i] = 3'b 000;
            4'b 1100: /* 2 */ ctz0[i] = 3'b 010;
            4'b 1101: /* 0 */ ctz0[i] = 3'b 000;
            4'b 1110: /* 1 */ ctz0[i] = 3'b 001;
            4'b 1111: /* 0 */ ctz0[i] = 3'b 000;
        endcase


    for(int i = 0; i < 4; i++)
        if(ctz0[2 * i] == 3'h4)
            ctz1[i] = ctz0[2 * i + 1] + 3'h4;
        else
            ctz1[i] = {1'b0, ctz0[2 * i]};


    for(int i = 0; i < 2; i++)
        if(ctz1[2 * i] == 4'h8)
            ctz2[i] = ctz1[2 * i + 1] + 4'h8;
        else
            ctz2[i] = {1'b0, ctz1[2 * i]};
    
    
    if(ctz2[0] == 5'h10)
        ctz3 = ctz2[1] + 5'h10;
    else
        ctz3 = {1'b0, ctz2[0]};
end

endmodule