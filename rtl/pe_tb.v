module pe_tb (
    
);

logic clk, rst; //  declare the clk and rst signals
logic [7:0] a_in, b_in;
logic [7:0] a_out, b_out;
logic [31:0] result_out;    

pe dut(
    .clk(clk), // connect the clk and rst signals to the dut
    .rst(rst),
    .a_in(a_in),
    .b_in(b_in),
    .a_out(a_out),
    .b_out(b_out),
    .result_out(result_out)
);
always #5 clk = ~clk;
initial begin
    clk = 0;// initialize the clk signal
    rst = 1;
    a_in = 0;
    b_in = 0;

    #20;
    rst = 0; // deassert the reset signal after some time

    a_in = 1;
    b_in = 2; //result should be 0 + (1*2) = 2

    #10;
    a_in = 3;
    b_in = 4; //result should be 2 + (3*4) = 14

    #10;
    $finish;

end

initial begin
        $monitor("Time=%0t | A=%d B=%d | Sum=%d", $time, a_in, b_in, result_out);
    end

    
endmodule