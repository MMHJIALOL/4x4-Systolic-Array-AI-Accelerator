`timescale 1ns / 1ps
module systolic_tb_4x4;

    logic rst, clk;
    logic [7:0] a0, a1, a2, a3; // rows of PEs
    logic [7:0] b0, b1, b2, b3; // columns of PEs

    logic [31:0] result00, result01, result02, result03;
    logic [31:0] result10, result11, result12, result13;
    logic [31:0] result20, result21, result22, result23;
    logic [31:0] result30, result31, result32, result33;    

    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .a0(a0),
        .a1(a1),
        .a2(a2),
        .a3(a3),
        .b0(b0),
        .b1(b1),
        .b2(b2),
        .b3(b3),
        .result00(result00), .result01(result01), .result02(result02), .result03(result03),
        .result10(result10), .result11(result11), .result12(result12), .result13(result13),
        .result20(result20), .result21(result21), .result22(result22), .result23(result23),
        .result30(result30), .result31(result31), .result32(result32), .result33(result33)
    );

    always #5 clk = ~clk;
initial begin
        $dumpfile("systolic_4x4.vcd");
        $dumpvars(0, systolic_tb_4x4);
        clk = 0;
        rst = 1;
        a0 = 0; a1 = 0; a2 = 0; a3 = 0;
        b0 = 0; b1 = 0; b2 = 0; b3 = 0; 

        #20;
        rst = 0;
        $display("--- Starting 4x4 Matrix Multiplication Test ---");
        
        // --- IMPORTANT: WAIT FOR CLOCK EDGE BEFORE DRIVING INPUTS ---
        @(posedge clk); 

        // Cycle 1
        a0 <= 1; b0 <= 2; 
        @(posedge clk); 

        // Cycle 2
        a0 <= 1; b0 <= 2; 
        a1 <= 1; b1 <= 2;
        @(posedge clk); 

        // Cycle 3
        a0 <= 1; b0 <= 2; 
        a1 <= 1; b1 <= 2; 
        a2 <= 1; b2 <= 2;
        @(posedge clk); 

        // Cycle 4
        a0 <= 1; b0 <= 2; 
        a1 <= 1; b1 <= 2; 
        a2 <= 1; b2 <= 2; 
        a3 <= 1; b3 <= 2; 
        @(posedge clk); 

        // Cycle 5 (Row 0 Done)
        a0 <= 0; b0 <= 0; 
        a1 <= 1; b1 <= 2; 
        a2 <= 1; b2 <= 2; 
        a3 <= 1; b3 <= 2; 
        @(posedge clk); 

        // Cycle 6
        a1 <= 0; b1 <= 0;
        a2 <= 1; b2 <= 2; 
        a3 <= 1; b3 <= 2;   
        @(posedge clk); 

        // Cycle 7
        a2 <= 0; b2 <= 0;
        a3 <= 1; b3 <= 2;   
        @(posedge clk); 

        // Cycle 8
        a3 <= 0; b3 <= 0;
        @(posedge clk); 

        // Wait for results to propagate
        repeat (10) @(posedge clk); 

        // Check Results
        if (result00 == 8 && result03 == 8 && result30 == 8 && result33 == 8) 
            $display("PASS: All corners are 8.");
        else 
            $display("FAIL: Expected 8. Got R00=%d R33=%d", result00, result33);
            
        $display("\nResult Matrix:");
        $display("%d %d %d %d", result00, result01, result02, result03);
        $display("%d %d %d %d", result10, result11, result12, result13);
        $display("%d %d %d %d", result20, result21, result22, result23);
        $display("%d %d %d %d", result30, result31, result32, result33);

        $finish;
    end
endmodule