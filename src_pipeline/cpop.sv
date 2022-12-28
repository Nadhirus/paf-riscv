// single cycle bit counter
module cpop(
    input [31:0] x,
    output [5:0] res
);

logic [2:0] add_part0 [0:7];
logic [3:0] add_part1 [0:3];
logic [4:0] add_part2 [0:1];

logic [5:0] bitsum;


wire  [3:0] x_parts  [0:7];

generate
    genvar i;
    for(i = 0; i < 8; i++)
        assign x_parts[i] = x[4 * i +:4];
endgenerate

assign res = bitsum;




// see https://everycircuit.com/circuit/4894778224279552/4-input-binary-adder
// 4 binary entry adder should be cheap


always_comb begin
    for(int i = 0; i < 8; i++)
        add_part0[i] = (x_parts[i][0] + x_parts[i][1])
                     + (x_parts[i][2] + x_parts[i][3]);
    
    for(int i = 0; i < 4; i++)
        add_part1[i] = add_part0[2 * i]
                     + add_part0[2 * i + 1];

    for(int i = 0; i < 2; i++)
        add_part2[i] = add_part1[2 * i]
                     + add_part1[2 * i + 1];


    bitsum = add_part2[0] + add_part2[1];
end 



endmodule