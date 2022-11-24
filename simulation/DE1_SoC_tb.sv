module DE1_SoC_tb();

    logic 	clock_50;
    logic [6:0] hex0;
    logic [6:0] hex1;
    logic [6:0] hex2;
    logic [6:0] hex3;
    logic [6:0] hex4;
    logic [6:0] hex5;
    logic [3:0]  key;
    logic [9:0] ledr;
    logic [9:0]   sw;
    logic 	 VGA_CLK;
    logic 	  VGA_HS;
    logic 	  VGA_VS;
    logic  VGA_BLANK;
    logic[7:0] VGA_R;
    logic[7:0] VGA_G;
    logic[7:0] VGA_B;
    logic 	VGA_SYNC;

    //test variables



    DE1_SoC DE1_SoC_test(.clock_50(clock_50), 
                         .hex0(hex0),
                         .hex1(hex1), 
                         .hex2(hex2), 
                         .hex3(hex3), 
                         .hex4(hex4), 
                         .hex5(hex5),
                         .key(key), 
                         .ledr(ledr), 
                         .sw(sw), 
                         .VGA_CLK(VGA_CLK), 
                         .VGA_HS(VGA_HS), 
                         .VGA_VS(VGA_VS), 
                         .VGA_BLANK(VGA_BLANK),
                         .VGA_R(VGA_R), 
                         .VGA_G(VGA_G), 
                         .VGA_B(VGA_B), 
                         .VGA_SYNC(VGA_SYNC));

    always
        begin
            #10ns
            clock_50 <= !clock_50;
        end

    initial begin
        clock_50 <= 1;
        sw <= 10'b1010_1010_10;
        key <= 4'b1100;

        #26ns

        key <= 4'b0101;
    end

endmodule