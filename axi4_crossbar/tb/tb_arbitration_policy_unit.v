
`timescale 1ns / 1ps

module tb_arbitration_policy_unit;

    reg aclk;
    reg aresetn;

    reg [1:0] arb_policy;
    reg [1:0] req;
    reg arb_enable;

    reg grant_accept;

    reg service_valid;
    reg service_master;

    reg epoch_clear;

    wire [1:0] grant;

    integer errors;

    arbitration_policy_unit DUT (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),
        .req(req),
        .arb_enable(arb_enable),
        .grant_accept(grant_accept),
        .service_valid(service_valid),
        .service_master(service_master),
        .epoch_clear(epoch_clear),
        .grant(grant)
    );

    // 100 MHz clock
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    task check_grant;
        input [1:0] expected;
        input [255:0] test_name;
        begin
            #1;
            if (grant !== expected) begin
                $display("FAIL: %s | Expected=%b Actual=%b",
                         test_name, expected, grant);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %s | Grant=%b",
                         test_name, grant);
            end
        end
    endtask

    initial begin

        errors = 0;

        aresetn = 0;
        arb_policy = 2'b00;
        req = 2'b00;
        arb_enable = 0;
        grant_accept = 0;
        service_valid = 0;
        service_master = 0;
        epoch_clear = 0;

        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        $display("\nARBITRATION POLICY UNIT TEST STARTED\n");

        // --------------------------------
        // POLICY 00: FIXED PRIORITY
        // --------------------------------

        arb_policy = 2'b00;
        arb_enable = 1;

        req = 2'b00;
        check_grant(2'b00, "Fixed: No requests");

        req = 2'b01;
        check_grant(2'b01, "Fixed: M0 only");

        req = 2'b10;
        check_grant(2'b10, "Fixed: M1 only");

        req = 2'b11;
        check_grant(2'b01, "Fixed: M0 has priority");

        // --------------------------------
        // POLICY 01: ROUND ROBIN
        // --------------------------------

        arb_policy = 2'b01;
        req = 2'b11;

        check_grant(2'b01, "RR: Initial priority M0");

        @(negedge aclk);
        grant_accept = 1;

        @(negedge aclk);
        grant_accept = 0;

        check_grant(2'b10, "RR: M1 after M0 accepted");

        @(negedge aclk);
        grant_accept = 1;

        @(negedge aclk);
        grant_accept = 0;

        check_grant(2'b01, "RR: M0 after M1 accepted");

        // --------------------------------
        // POLICY 10: BURST-AGE
        // --------------------------------

        arb_policy = 2'b10;
        req = 2'b11;
        epoch_clear = 1;

        @(negedge aclk);
        epoch_clear = 0;

        // Initial tie: expect M0
        check_grant(2'b01, "Age: Initial tie");

        @(negedge aclk);
        grant_accept = 1;

        @(negedge aclk);
        grant_accept = 0;

        // Build service history for M0
        service_master = 0;
        service_valid = 1;

        repeat (3) @(negedge aclk);

        service_valid = 0;

        #1;
        $display("INFO: Age-based arbitration after M0 service history: Grant=%b",
                 grant);

        // --------------------------------
        // POLICY 11: RESERVED
        // --------------------------------

        arb_policy = 2'b11;
        check_grant(2'b00, "Reserved policy");

        // --------------------------------
        // ARBITRATION DISABLED
        // --------------------------------

        arb_policy = 2'b00;
        arb_enable = 0;
        req = 2'b11;

        check_grant(2'b00, "Arbitration disabled");

        // --------------------------------
        // RESULTS
        // --------------------------------

        if (errors == 0) begin
            $display("\nALL POLICY UNIT CHECKS PASSED!");
        end
        else begin
            $display("\nTEST FAILED: %0d errors", errors);
        end

        $finish;
    end

endmodule
