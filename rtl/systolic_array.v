module systolic_array (
    input logic clk, rst,

    input logic [7:0] a0, a1, a2, a3, // inputs to the first rows of PEs
    input logic [7:0] b0, b1, b2, b3, // inputs to the first columns of PEs

    output logic [31:0] result00, result01, result02, result03, // outputs of the first row of PEs  
    output logic [31:0] result10, result11, result12, result13, // outputs of the second row of PEs
    output logic [31:0] result20, result21, result22, result23,
    output logic [31:0] result30, result31, result32, result33
);

//wires to connect inside the array of PEs
logic [7:0] a00, a01, a02, a03; // for row 0
logic [7:0] a10, a11, a12, a13; // for row 1 
logic [7:0] a20, a21, a22, a23; // for row 2
logic [7:0] a30, a31, a32, a33; // for row 3        

logic [7:0] b00, b01, b02, b03; // for column 0
logic [7:0] b10, b11, b12, b13; // for column 1
logic [7:0] b20, b21, b22, b23; // for column 2
logic [7:0] b30, b31, b32, b33; // for column 3

// ROW 0 Col 0
pe pe00 (
    .clk(clk),
    .rst(rst),
    .a_in(a0), // input from outside
    .b_in(b0), // input from outside
    .a_out(a00), // output to the right
    .b_out(b00), // output downwards
    .result_out(result00) // output result
);
// ROW 0 Col 1
pe pe01 (
    .clk(clk),
    .rst(rst),
    .a_in(a00), // input from the left PE
    .b_in(b1), // input from outside
    .a_out(a01), // output to the right
    .b_out(b01), // output downwards
    .result_out(result01) // output result
);
// ROW 0 Col 2
pe pe02 (
    .clk(clk),
    .rst(rst),
    .a_in(a01), // input from the left PE
    .b_in(b2), // input from outside
    .a_out(a02), // output to the right
    .b_out(b02), // output downwards
    .result_out(result02) // output result
);
// ROW 0 Col 3
pe pe03 (
    .clk(clk),
    .rst(rst),
    .a_in(a02), // input from the left PE
    .b_in(b3), // input from outside
    .a_out(a03), // output to the right
    .b_out(b03), // output downwards
    .result_out(result03) // output result
);  
// ROW 1 Col 0
pe pe10 (
    .clk(clk),
    .rst(rst),
    .a_in(a1), // input from outside
    .b_in(b00), // input from the top PE
    .a_out(a10), // output to the right
    .b_out(b10), // output downwards
    .result_out(result10) // output result
);
// ROW 1 Col 1
pe pe11 (
    .clk(clk),
    .rst(rst),
    .a_in(a10), // input from the left PE
    .b_in(b01), // input from the top PE
    .a_out(a11), // output to the right
    .b_out(b11), // output downwards
    .result_out(result11) // output result
);
// ROW 1 Col 2
pe pe12 (
    .clk(clk),
    .rst(rst),
    .a_in(a11), // input from the left PE
    .b_in(b02), // input from the top PE
    .a_out(a12), // output to the right
    .b_out(b12), // output downwards
    .result_out(result12) // output result
);
// ROW 1 Col 3
pe pe13 (
    .clk(clk),
    .rst(rst),
    .a_in(a12), // input from the left PE
    .b_in(b03), // input from the top PE
    .a_out(a13), // output to the right
    .b_out(b13), // output downwards
    .result_out(result13) // output result
);
// ROW 2 Col 0
pe pe20 (
    .clk(clk),
    .rst(rst),
    .a_in(a2), // input from outside
    .b_in(b10), // input from the top PE
    .a_out(a20), // output to the right
    .b_out(b20), // output downwards
    .result_out(result20) // output result
);
// ROW 2 Col 1
pe pe21 (
    .clk(clk),
    .rst(rst),
    .a_in(a20), // input from the left PE
    .b_in(b11), // input from the top PE
    .a_out(a21), // output to the right
    .b_out(b21), // output downwards
    .result_out(result21) // output result
);
// ROW 2 Col 2
pe pe22 (
    .clk(clk),
    .rst(rst),
    .a_in(a21), // input from the left PE
    .b_in(b12), // input from the top PE
    .a_out(a22), // output to the right
    .b_out(b22), // output downwards
    .result_out(result22) // output result
);
// ROW 2 Col 3
pe pe23 (
    .clk(clk),
    .rst(rst),
    .a_in(a22), // input from the left PE
    .b_in(b13), // input from the top PE
    .a_out(a23), // output to the right
    .b_out(b23), // output downwards
    .result_out(result23) // output result
);
// ROW 3 Col 0
pe pe30 (
    .clk(clk),
    .rst(rst),
    .a_in(a3), // input from outside
    .b_in(b20), // input from the top PE
    .a_out(a30), // output to the right
    .b_out(b30), // output downwards
    .result_out(result30) // output result
);
// ROW 3 Col 1
pe pe31 (
    .clk(clk),
    .rst(rst),
    .a_in(a30), // input from the left PE
    .b_in(b21), // input from the top PE
    .a_out(a31), // output to the right
    .b_out(b31), // output downwards
    .result_out(result31) // output result
);
// ROW 3 Col 2
pe pe32 (
    .clk(clk),
    .rst(rst),
    .a_in(a31), // input from the left PE
    .b_in(b22), // input from the top PE
    .a_out(a32), // output to the right
    .b_out(b32), // output downwards
    .result_out(result32) // output result
);
// ROW 3 Col 3
pe pe33 (
    .clk(clk),
    .rst(rst),
    .a_in(a32), // input from the left PE
    .b_in(b23), // input from the top PE
    .a_out(a33), // output to the right
    .b_out(b33), // output downwards
    .result_out(result33) // output result
);
    
endmodule