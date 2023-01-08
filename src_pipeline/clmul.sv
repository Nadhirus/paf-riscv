// two-cycle carry-less multiplier
module clmul(
    input  clk,
    input  resetn,
    input  start,
    input  stall,
    output eoc,
    
    input [31:0] A, 
    input [31:0] B,

    output [63:0] res, 
    output [63:0] res_r
);

wire [63:0] A_ext = {32'b0, A};
logic [63:0] its [0:31];

localparam IT_PER_CYCLE = 8;
localparam STALL_CYC_COUNT = 32 / IT_PER_CYCLE;
localparam STATE_BITS = $clog2(STALL_CYC_COUNT + 1);


wire [63:0] mul_parts [0:IT_PER_CYCLE - 1];


logic [63:0] acc;
logic [63:0] acc_A;
logic [31:0] acc_B;

// counts down to stall 32 / IT_PER_CYCLE cycles 
logic [STATE_BITS - 1:0] state;


generate
    genvar i;
    for(i = 0; i < IT_PER_CYCLE; i++) begin: mul_parts
        assign mul_parts[i] = acc_A << i;
    end
endgenerate

logic [63:0] acc_next;
always_comb begin
    acc_next = acc;
    for(int i = 0; i < IT_PER_CYCLE; i++)
        acc_next = acc_B[i] ? acc_next ^ mul_parts[i] : acc_next;
end



always_ff @(posedge clk)
    if(!resetn) begin
        acc   <= '0;
        acc_A <= '0;
        acc_B <= '0;
        state <= '0;
    end else begin
        if(!stall)  begin
            if(start) begin
                // data
                acc   <= '0;
                acc_A <= {32'h0, A};
                acc_B <= B;
                
                // control
                state <= STALL_CYC_COUNT;
            end
            else begin
            // data
                acc   <= acc_next;
                acc_A <= acc_A << IT_PER_CYCLE;
                acc_B <= acc_B >> IT_PER_CYCLE;

                // control
                if(state != 0)
                    state <= state - 1;
            end
        end
    end

assign eoc = state == 0 && !start;
assign res = acc_next;




logic [63:0] its_r [0:31];
assign res_r = its_r[31];

always_comb begin
    its_r[0] = B[31] ? A_ext : 0;

    for(int i = 1; i < 32; i++) begin
        if(B[31 - i])
            its_r[i] = its_r[i - 1] ^ (A_ext << i);
        else
            its_r[i] = its_r[i - 1];
    end
end

endmodule