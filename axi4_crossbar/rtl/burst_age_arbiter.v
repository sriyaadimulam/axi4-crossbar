
`timescale 1ns / 1ps

module burst_age_arbiter (

    input wire aclk,
    input wire aresetn,

    input wire [1:0] req,
    input wire arb_enable,

    input wire grant_accept,

    input wire service_valid,
    input wire service_master,

    input wire epoch_clear,

    output wire [1:0] grant

);

    // 32-bit saturating counters
    reg [31:0] age0;
    reg [31:0] age1;

    reg [31:0] service0;
    reg [31:0] service1;

    // Round-robin tie-break state
    // 0: Master 0 has priority
    // 1: Master 1 has priority
    reg rr_priority;

    // Grant lock for AXI backpressure stability
    reg lock_valid;
    reg [1:0] locked_grant;

    // Priority score calculation
    reg [31:0] max_service;
    reg [31:0] service_diff0;
    reg [31:0] service_diff1;

    reg [33:0] score0;
    reg [33:0] score1;

    reg [1:0] selected_grant;

    // Combinational priority calculation
    always @(*) begin

        max_service = (service0 >= service1) ?
                       service0 : service1;

        service_diff0 = max_service - service0;
        service_diff1 = max_service - service1;

        // P = Waiting age + 2 * Service difference
        score0 = {2'b00, age0} +
                 {1'b0, service_diff0, 1'b0};

        score1 = {2'b00, age1} +
                 {1'b0, service_diff1, 1'b0};

        selected_grant = 2'b00;

        if (req[0] && req[1]) begin

            if (score0 > score1)
                selected_grant = 2'b01;

            else if (score1 > score0)
                selected_grant = 2'b10;

            else if (rr_priority == 1'b0)
                selected_grant = 2'b01;

            else
                selected_grant = 2'b10;

        end

        else if (req[0])
            selected_grant = 2'b01;

        else if (req[1])
            selected_grant = 2'b10;

    end

    // Grant output:
    // Keep the selected master stable until acceptance.
    assign grant = lock_valid ?
                   locked_grant :
                   (arb_enable ? selected_grant : 2'b00);


    // Sequential state updates
    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin

            age0 <= 32'd0;
            age1 <= 32'd0;

            service0 <= 32'd0;
            service1 <= 32'd0;

            rr_priority <= 1'b0;

            lock_valid <= 1'b0;
            locked_grant <= 2'b00;

        end

        else begin

            // Waiting age: Master 0
            if (!req[0] || (grant_accept && grant[0]))
                age0 <= 32'd0;

            else if (age0 != 32'hFFFFFFFF)
                age0 <= age0 + 1'b1;


            // Waiting age: Master 1
            if (!req[1] || (grant_accept && grant[1]))
                age1 <= 32'd0;

            else if (age1 != 32'hFFFFFFFF)
                age1 <= age1 + 1'b1;


            // Service accounting
            if (epoch_clear) begin

                service0 <= 32'd0;
                service1 <= 32'd0;

            end

            else if (service_valid) begin

                if (service_master == 1'b0) begin

                    if (service0 != 32'hFFFFFFFF)
                        service0 <= service0 + 1'b1;

                end

                else begin

                    if (service1 != 32'hFFFFFFFF)
                        service1 <= service1 + 1'b1;

                end

            end


            // Round-robin tie-break update
            if (grant_accept && grant != 2'b00) begin

                if (grant == 2'b01)
                    rr_priority <= 1'b1;

                else if (grant == 2'b10)
                    rr_priority <= 1'b0;

            end


            // Lock selected grant until address acceptance
            if (lock_valid) begin

                if (grant_accept)
                    lock_valid <= 1'b0;

            end

            else if (arb_enable &&
                     selected_grant != 2'b00 &&
                     !grant_accept) begin

                lock_valid <= 1'b1;
                locked_grant <= selected_grant;

            end

        end

    end

endmodule
