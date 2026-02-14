// Connects AXI -> Buffers -> Delays -> Systolic Array
module top (
    input logic clk, rst,
    // AXI port A (Buffer A)
    input logic s_axis_a_valid,
    output logic s_axis_a_ready,
    input logic [7:0] s_axis_a_data,

    // AXI port B (Buffer B)
    input logic s_axis_b_valid,
    output logic s_axis_b_ready,
    input logic [7:0] s_axis_b_data,

    // Control signals
    input  logic       start_compute, 
    output logic       done,          

    // In a real chip, this would go to an Output Buffer/AXI
    output logic [31:0] result00, result01, result02, result03,
    output logic [31:0] result10, result11, result12, result13,
    output logic [31:0] result20, result21, result22, result23,
    output logic [31:0] result30, result31, result32, result33
);

    logic [7:0] raw_a0, raw_a1, raw_a2, raw_a3, raw_b0, raw_b1, raw_b2, raw_b3; // raw data from AXI buffer A and B the read data part at the end of the buffer.v code
    // FSMs replaces the manual control. It automatically runs the array for 
    // a set number of cycles (15) and then triggers 'done'.    
    // States
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        COMPUTE = 2'b01,
        FINISH  = 2'b10
    } state_t;

    state_t state;
    logic [4:0] count;   // Timer to count cycles
    logic enable_signal; // Internal signal to turn on Buffers

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            count <= 0;
            enable_signal <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    count <= 0;
                    enable_signal <= 0;
                    if (start_compute) begin
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    enable_signal <= 1; // Turn on the Buffers!
                    count <= count + 1;
                    
                    // We wait 15 cycles: 4 cycles for data input + 11 cycles for propagation
                    if (count == 15) begin
                        state <= FINISH;
                    end
                end

                FINISH: begin
                    enable_signal <= 0;
                    done <= 1; // Tell the CPU we are finished
                    state <= IDLE;
                end
            endcase
        end
    end

    buffer buf_a (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_a_valid),
        .s_axis_tready(s_axis_a_ready),
        .s_axis_tdata({24'b0, s_axis_a_data}), 
        .row0(raw_a0),
        .row1(raw_a1),
        .row2(raw_a2),
        .row3(raw_a3),
        .read_enable(enable_signal) // start reading when FSM says so (Changed from start_compute)
    );

    buffer buf_b (
        .clk(clk),
        .rst(rst),
        .s_axis_tvalid(s_axis_b_valid),
        .s_axis_tready(s_axis_b_ready),
        .s_axis_tdata({24'b0, s_axis_b_data}),
        .row0(raw_b0),
        .row1(raw_b1),
        .row2(raw_b2),
        .row3(raw_b3),
        .read_enable(enable_signal) // start reading when FSM says so (Changed from start_compute)
    );

    // Delays will be added here because array needs delay of data and can't implement data all at once, our buffer throws
    // all the data at once but we need to delay the data to match the flow of the array, we can use shift registers for this  
    // Registers for A
    logic [7:0] a1_d1;
    logic [7:0] a2_d1, a2_d2;
    logic [7:0] a3_d1, a3_d2, a3_d3;

    // Registers for B 
    logic [7:0] b1_d1;
    logic [7:0] b2_d1, b2_d2;
    logic [7:0] b3_d1, b3_d2, b3_d3;

    always @(posedge clk or posedge rst)begin
        if (rst == 1) begin
            a1_d1 <= 0; 
            a2_d1 <= 0; a2_d2 <= 0;
            a3_d1 <= 0; a3_d2 <= 0; a3_d3 <= 0;

            b1_d1 <= 0;
            b2_d1 <= 0; b2_d2 <= 0;
            b3_d1 <= 0; b3_d2 <= 0; b3_d3 <= 0;
        end else begin
            // Delays for A
            a1_d1 <= raw_a1; // cycle 1
            a2_d1 <= raw_a2; a2_d2 <= a2_d1; //cycle 2 
            a3_d1 <= raw_a3; a3_d2 <= a3_d1; a3_d3 <= a3_d2; //cycle 3

            // Delays for B
            b1_d1 <= raw_b1;
            b2_d1 <= raw_b2; b2_d2 <= b2_d1;
            b3_d1 <= raw_b3; b3_d2 <= b3_d1; b3_d3 <= b3_d2;
        end 
    end

    // Now we can connect the delayed signals to the array, we will connect the raw_a0 and raw_b0 directly 
    // to the array as they don't need any delay
    systolic_array arr (
        .clk(clk),
        .rst(rst),
        .a0(raw_a0), .a1(a1_d1), .a2(a2_d2), .a3(a3_d3),
        .b0(raw_b0), .b1(b1_d1), .b2(b2_d2), .b3(b3_d3),
        .result00(result00), .result01(result01), .result02(result02), .result03(result03),
        .result10(result10), .result11(result11), .result12(result12), .result13(result13),
        .result20(result20), .result21(result21), .result22(result22), .result23(result23),
        .result30(result30), .result31(result31), .result32(result32), .result33(result33)
    );  
endmodule