
`timescale 1ns / 1ps

module fixed_priority_arbiter (

    input  wire [1:0] req,
    output reg  [1:0] grant

);

    always @(*) begin

        // Default: no master is granted
        grant = 2'b00;

        // Master 0 has the highest priority
        if (req[0]) begin
            grant = 2'b01;
        end

        // Master 1 is granted only if Master 0 is not requesting
        else if (req[1]) begin
            grant = 2'b10;
        end

    end

endmodule
