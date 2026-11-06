
`timescale 1ns / 1ps

   module master_tracker (

    input wire aclk,
    input wire aresetn,

    // Master 0 transaction events
    input wire m0_ar_accept,
    input wire m0_read_complete,

    input wire m0_aw_accept,
    input wire m0_write_complete,

    // Master 1 transaction events
    input wire m1_ar_accept,
    input wire m1_read_complete,

    input wire m1_aw_accept,
    input wire m1_write_complete,

    // Master 0 status
    output reg m0_read_busy,
    output reg m0_write_busy,

    // Master 1 status
    output reg m1_read_busy,
    output reg m1_write_busy,

    // Transaction availability
    output wire m0_read_available,
    output wire m0_write_available,

    output wire m1_read_available,
    output wire m1_write_available
);

    // Availability is the inverse of busy status
    assign m0_read_available  = ~m0_read_busy;
    assign m0_write_available = ~m0_write_busy;

    assign m1_read_available  = ~m1_read_busy;
    assign m1_write_available = ~m1_write_busy;


    // Transaction tracking
    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin

            m0_read_busy  <= 1'b0;
            m0_write_busy <= 1'b0;

            m1_read_busy  <= 1'b0;
            m1_write_busy <= 1'b0;

        end
        else begin

            // Master 0 read tracking
            if (m0_ar_accept)
                m0_read_busy <= 1'b1;
            else if (m0_read_complete)
                m0_read_busy <= 1'b0;


            // Master 0 write tracking
            if (m0_aw_accept)
                m0_write_busy <= 1'b1;
            else if (m0_write_complete)
                m0_write_busy <= 1'b0;


            // Master 1 read tracking
            if (m1_ar_accept)
                m1_read_busy <= 1'b1;
            else if (m1_read_complete)
                m1_read_busy <= 1'b0;


            // Master 1 write tracking
            if (m1_aw_accept)
                m1_write_busy <= 1'b1;
            else if (m1_write_complete)
                m1_write_busy <= 1'b0;

        end
    end

endmodule
