module pe (
    input logic clk,
    input logic rst,

    input logic [7:0] a_in,
    input logic [7:0] b_in,

    output logic [7:0] a_out,
    output logic [7:0] b_out,
    
    output logic [31:0] result_out // we are doing sum + product which will exceed the 16 bits hence using the 32 bits
);
    
// logic [31:0] product;
always_ff @(posedge clk or posedge rst) begin

    if (rst) begin 
        a_out <= 8'b0; //assign a and b to 0 on reset
        b_out <= 8'b0;
        result_out <= 32'b0; //new sum = old sum + product, hence old sum = 0
    end 
    
    else begin
        a_out <= a_in;
        b_out <= b_in;
        // product <= a_in * b_in; // calculate the product
        result_out <= result_out + (a_in * b_in); // sum + product
    end
end
endmodule