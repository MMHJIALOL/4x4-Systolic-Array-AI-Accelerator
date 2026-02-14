`timescale 1ns / 1ps

module top_tb;

    // --- 1. SIGNALS ---
    logic clk, rst;

    // AXI Port A (Rows)
    logic [7:0] s_axis_a_data;
    logic       s_axis_a_valid;
    logic       s_axis_a_ready;

    // AXI Port B (Columns)
    logic [7:0] s_axis_b_data;
    logic       s_axis_b_valid;
    logic       s_axis_b_ready;

    // Control
    logic start_compute;
    logic done;

    // Outputs (The Result Matrix)
    logic [31:0] result00, result01, result02, result03;
    logic [31:0] result10, result11, result12, result13;
    logic [31:0] result20, result21, result22, result23;
    logic [31:0] result30, result31, result32, result33;

    // --- 2. INSTANTIATE THE CHIP (TOP) ---
    top uut (
        .clk(clk), .rst(rst),
        
        // Port A
        .s_axis_a_data(s_axis_a_data), 
        .s_axis_a_valid(s_axis_a_valid), 
        .s_axis_a_ready(s_axis_a_ready),

        // Port B
        .s_axis_b_data(s_axis_b_data), 
        .s_axis_b_valid(s_axis_b_valid), 
        .s_axis_b_ready(s_axis_b_ready),

        // Control
        .start_compute(start_compute), .done(done),

        // Results
        .result00(result00), .result01(result01), .result02(result02), .result03(result03),
        .result10(result10), .result11(result11), .result12(result12), .result13(result13),
        .result20(result20), .result21(result21), .result22(result22), .result23(result23),
        .result30(result30), .result31(result31), .result32(result32), .result33(result33)
    );

    // --- 3. CLOCK GENERATION ---
    always #5 clk = ~clk; // 100MHz Clock

    // --- 4. CPU WRITE TASK ---
    task write_a(input [7:0] value);
        begin
            @(posedge clk); 
            s_axis_a_valid <= 1;
            s_axis_a_data  <= value;
            wait(s_axis_a_ready); 
            @(posedge clk);
            s_axis_a_valid <= 0;
        end
    endtask

    task write_b(input [7:0] value);
        begin
            @(posedge clk);
            s_axis_b_valid <= 1;
            s_axis_b_data  <= value;
            wait(s_axis_b_ready);
            @(posedge clk);
            s_axis_b_valid <= 0;
        end
    endtask

    // --- 5. THE MAIN TEST ---
    initial begin
        $dumpfile("final_chip.vcd");
        $dumpvars(0, top_tb);

        // Initialize
        clk = 0; rst = 1;
        s_axis_a_valid = 0; s_axis_a_data = 0;
        s_axis_b_valid = 0; s_axis_b_data = 0;
        start_compute = 0;

        // Reset Pulse
        #20 rst = 0;
        
        // --- PHASE 1: Load Matrix A (Rows) ---
        $display("Loading Buffer A...");
        repeat(16) write_a(8'd1); 

        // --- PHASE 2: Load Matrix B (Columns) ---
        $display("Loading Buffer B...");
        repeat(16) write_b(8'd2); 

        repeat(5) @(posedge clk); 

        // --- PHASE 3: START COMPUTE (FSM TRIGGER) ---
        $display("Starting Computation...");
        
        // Pulse the Start Signal
        @(posedge clk);
        start_compute <= 1;
        @(posedge clk);
        start_compute <= 0; // The FSM takes over from here!

        // --- NEW: Wait for the Chip to say "DONE" ---
        $display("Waiting for Done Signal...");
        wait(done == 1);
        $display("Done Signal Received!");

        // --- PHASE 4: CHECK RESULTS ---
        $display("--------------------------------");
        $display("Result Matrix:");
        $display("[%d] [%d] [%d] [%d]", result00, result01, result02, result03);
        $display("[%d] [%d] [%d] [%d]", result10, result11, result12, result13);
        $display("[%d] [%d] [%d] [%d]", result20, result21, result22, result23);
        $display("[%d] [%d] [%d] [%d]", result30, result31, result32, result33);
        $display("--------------------------------");

        if (result00 == 8 && result33 == 8) 
            $display("SUCCESS: System Verified with FSM Control.");
        else 
            $display("FAILURE: Expected 8.");

        $finish;
    end

endmodule