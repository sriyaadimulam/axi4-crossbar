
`timescale 1ns / 1ps

module round_robin_arbiter (

    input  wire       aclk,
    input  wire       aresetn,

    input  wire [1:0] req,
    input  wire       grant_accept,

    output reg  [1:0] grant

);

    // 0: Master 0 has priority
    // 1: Master 1 has priority
    reg rr_priority;


    // Combinational arbitration
    always @(*) begin

        grant = 2'b00;

        if (rr_priority == 1'b0) begin

            if (req[0])
                grant = 2'b01;
            else if (req[1])
                grant = 2'b10;

        end
        else begin

            if (req[1])
                grant = 2'b10;
            else if (req[0])
                grant = 2'b01;

        end

    end


    // Update priority only after an accepted grant
    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn)
            rr_priority <= 1'b0;

        else if (grant_accept) begin

            if (grant == 2'b01)
                rr_priority <= 1'b1;

            else if (grant == 2'b10)
                rr_priority <= 1'b0;

        end

    end

endmodule
