module control_unit (
    input logic clk, rst,
    input logic start, enable_array, done
);

    // State Encoding
    typedef enum logic [1:0] {
            IDLE    = 2'b00,
            COMPUTE = 2'b01,
            FINISH  = 2'b10
        } state_t;

    state_t current_state, next_state;
    logic [5:0] count; // Counts the number of compute cycles (5 bits for counting up to 32)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
            count <= 0;
        end else begin
            current_state <= next_state;

            // Increment compute counter in COMPUTE state
            if (current_state == COMPUTE) begin
                count <= count + 1;
            end else begin
                count <= 0; // Reset counter in other states
            end
        end

        always_comb begin
            // Default values
            next_state = current_state;
            enable_array = 0;
            done = 0;

            case (current_state)
                IDLE: begin
                    if (start) begin
                        next_state = COMPUTE;
                    end
                end

                COMPUTE: begin
                    enable_array = 1; // Enable the array to start processing

                    // After 16 cycles of computation, move to FINISH state
                    if (count == 15) begin
                        next_state = FINISH;
                    end
                end

                FINISH: begin
                    // Stay in FINISH state until reset
                end
                done = 1;
                default: next_state = IDLE;
            endcase
        end
    end
    
endmodule