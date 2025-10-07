/*
* Module describing a 32-bit ripple carry adder, with no carry output or input
*/
module adder32 import calculator_pkg::*; (
    input logic [DATA_W - 1 : 0] a_i,
    input logic [DATA_W - 1 : 0] b_i,
    output logic [DATA_W - 1 : 0] sum_o
);

    //TODO: use a generate block to chain together 32 full adders. 
    // Imagine you are connecting 32 single-bit adder modules together.
    logic [DATA_W:0] c;
    assign c[0] = 1'b0;

    generate
        for (genvar i=0; i < DATA_W; i++) begin: ripple
            full_adder fa(
                .a (a_i[i]),
                .b (b_i[i]),
                .cin(c[i]),
                .s (sum_o[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

endmodule