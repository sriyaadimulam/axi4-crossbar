
`timescale 1ns / 1ps

module arbitration_policy_unit_locked (
    input wire aclk,
    input wire aresetn,

    input wire [1:0] arb_policy,
    input wire [1:0] req,
    input wire arb_enable,

    input wire grant_accept,

    input wire service_valid,
    input wire service_master,

    input wire epoch_clear,

    output wire [1:0] grant
);

    reg locked;
    reg [1:0] locked_grant;

    wire [1:0] effective_req;
    wire effective_enable;
    wire [1:0] policy_grant;

    // While locked, allow only the previously selected master
    // to participate in arbitration.
    assign effective_req =
        locked ? locked_grant : req;

    // Keep arbitration enabled while a grant is locked.
    assign effective_enable =
        arb_enable || locked;

    // Existing arbitration policy unit.
    arbitration_policy_unit U_POLICY (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),
        .req(effective_req),
        .arb_enable(effective_enable),
        .grant_accept(grant_accept),
        .service_valid(service_valid),
        .service_master(service_master),
        .epoch_clear(epoch_clear),
        .grant(policy_grant)
    );

    // Present the locked grant until its handshake completes.
    assign grant =
        locked ? locked_grant : policy_grant;

    // Grant locking.
    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            locked      <= 1'b0;
            locked_grant <= 2'b00;
        end

        else begin

            if (locked) begin

                // Release the lock after the accepted handshake.
                if (grant_accept) begin
                    locked       <= 1'b0;
                    locked_grant <= 2'b00;
                end

            end

            else if (
                arb_enable &&
                (policy_grant != 2'b00) &&
                !grant_accept
            ) begin

                // Capture the selected master during a stall.
                locked       <= 1'b1;
                locked_grant <= policy_grant;

            end

        end
    end

endmodule
