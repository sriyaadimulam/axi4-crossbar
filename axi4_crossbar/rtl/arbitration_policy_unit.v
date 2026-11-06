
`timescale 1ns / 1ps

module arbitration_policy_unit (
    input wire aclk,
    input wire aresetn,

    input wire [1:0] arb_policy,
    input wire [1:0] req,
    input wire arb_enable,

    input wire grant_accept,

    input wire service_valid,
    input wire service_master,

    input wire epoch_clear,

    output reg [1:0] grant
);

    wire [1:0] fixed_grant;
    wire [1:0] rr_grant;
    wire [1:0] age_grant;

    wire rr_accept;
    wire age_accept;
    wire age_service_valid;

    assign rr_accept =
        grant_accept &&
        arb_enable &&
        (arb_policy == 2'b01) &&
        (rr_grant != 2'b00);

    assign age_accept =
        grant_accept &&
        arb_enable &&
        (arb_policy == 2'b10) &&
        (age_grant != 2'b00);

    assign age_service_valid =
        service_valid && (arb_policy == 2'b10);

    // Fixed-priority arbiter
    fixed_priority_arbiter U_FIXED (
        .req(req),
        .grant(fixed_grant)
    );

    // Round-robin arbiter
    round_robin_arbiter U_RR (
        .aclk(aclk),
        .aresetn(aresetn),
        .req(req),
        .grant_accept(rr_accept),
        .grant(rr_grant)
    );

    // Burst-aware age-based arbiter
    burst_age_arbiter U_AGE (
        .aclk(aclk),
        .aresetn(aresetn),
        .req(req),
        .arb_enable(arb_enable && (arb_policy == 2'b10)),
        .grant_accept(age_accept),
        .service_valid(age_service_valid),
        .service_master(service_master),
        .epoch_clear(epoch_clear),
        .grant(age_grant)
    );

    // Select the configured policy
    always @(*) begin
        grant = 2'b00;

        if (arb_enable) begin
            case (arb_policy)

                2'b00: grant = fixed_grant;

                2'b01: grant = rr_grant;

                2'b10: grant = age_grant;

                default: grant = 2'b00;

            endcase
        end
    end

endmodule
