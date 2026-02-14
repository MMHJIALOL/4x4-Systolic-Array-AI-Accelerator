// This acts as a bridge between the outside world (AXI) and your Array.
module buffer (
    input logic clk, rst,
    input logic s_axis_tvalid, // AXI stream valid signal (master)
    output logic s_axis_tready, // AXI stream ready signal (slave)
    input logic [31:0] s_axis_tdata, // AXI stream data input

    output logic [7:0] row0, row1, row2, row3, // outputs to the systolic array
    input logic read_enable // signal to enable reading from the buffer
);

// Internal buffer to hold the data before sending to the systolic array
    logic [7:0] mem [0:15]; // 16 rows of 8 bits each
    logic [3:0] write_ptr; // pointer for writing data into the buffer (is of 16 bits because 15 entries and can't be represented in less than 4 bits)
    logic full_flag; // flag to indicate buffer is full

    logic [2:0] read_ptr; // pointer for reading data from the buffer


    assign s_axis_tready = ~full_flag; // ready to accept data when buffer is not full

// Logic to write incoming data into the buffer
    always_ff @(posedge clk or posedge rst) begin
        if(rst == 1) begin
            write_ptr = 0;
            full_flag = 0;
        end else if ((s_axis_tvalid && s_axis_tready) == 1) begin
            mem[write_ptr] <= s_axis_tdata[7:0]; // write the lower 8 bits of the input data to the buffer
            write_ptr <= write_ptr + 1; // increment the write pointer
            if (write_ptr == 15) begin
                full_flag <= 1; // set the full flag when the buffer is full
            end
        end
    end

// Logic to read from the buffer and send data to the systolic array
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            read_ptr <= 0;
            row0 <= 0; row1 <= 0; row2 <= 0; row3 <= 0;
        end 
        else if (read_enable) begin
            if (read_ptr < 4) begin
                row0 <= mem[0 + read_ptr];   
                row1 <= mem[4 + read_ptr];   
                row2 <= mem[8 + read_ptr];   
                row3 <= mem[12 + read_ptr];  
                
                read_ptr <= read_ptr + 1; 
            end else begin
                // We are done sending 4 values. Send Zeros now.
                row0 <= 0; row1 <= 0; row2 <= 0; row3 <= 0;
            end
        end 
        else begin
            // Reset the reader when not computing
            read_ptr <= 0;
            row0 <= 0; row1 <= 0; row2 <= 0; row3 <= 0;
        end
    end       

endmodule