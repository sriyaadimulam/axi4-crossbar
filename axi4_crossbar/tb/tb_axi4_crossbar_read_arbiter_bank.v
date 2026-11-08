
`timescale 1ns / 1ps

module tb_axi4_crossbar_read_arbiter_bank;

    reg aclk;
    reg aresetn;
    reg [1:0] arb_policy;

    reg [1:0] s0_rd_req;
    reg s0_rd_enable;
    reg s0_rd_grant_accept;
    reg s0_rd_service_valid;
    reg s0_rd_service_master;
    reg s0_rd_epoch_clear;

    reg [1:0] s1_rd_req;
    reg s1_rd_enable;
    reg s1_rd_grant_accept;
    reg s1_rd_service_valid;
    reg s1_rd_service_master;
    reg s1_rd_epoch_clear;

    wire [1:0] s0_rd_grant;
    wire [1:0] s1_rd_grant;

    integer passed;
    integer failed;

    axi4_crossbar_read_arbiter_bank DUT (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        .s0_rd_req(s0_rd_req),
        .s0_rd_enable(s0_rd_enable),
        .s0_rd_grant_accept(s0_rd_grant_accept),
        .s0_rd_service_valid(s0_rd_service_valid),
        .s0_rd_service_master(s0_rd_service_master),
        .s0_rd_epoch_clear(s0_rd_epoch_clear),
        .s0_rd_grant(s0_rd_grant),

        .s1_rd_req(s1_rd_req),
        .s1_rd_enable(s1_rd_enable),
        .s1_rd_grant_accept(s1_rd_grant_accept),
        .s1_rd_service_valid(s1_rd_service_valid),
        .s1_rd_service_master(s1_rd_service_master),
        .s1_rd_epoch_clear(s1_rd_epoch_clear),
        .s1_rd_grant(s1_rd_grant)
    );

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    task check_grants;
        input [1:0] expected_s0;
        input [1:0] expected_s1;
        input [200*8-1:0] test_name;
        begin
            #1;
            if ((s0_rd_grant === expected_s0) &&
                (s1_rd_grant === expected_s1)) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s | S0 expected=%b actual=%b | S1 expected=%b actual=%b",
                    test_name,
                    expected_s0, s0_rd_grant,
                    expected_s1, s1_rd_grant);
                failed = failed + 1;
            end
        end
    endtask

    initial begin

        passed = 0;
        failed = 0;

        aresetn = 0;
        arb_policy = 2'b00;

        s0_rd_req = 0;
        s0_rd_enable = 0;
        s0_rd_grant_accept = 0;
        s0_rd_service_valid = 0;
        s0_rd_service_master = 0;
        s0_rd_epoch_clear = 0;

        s1_rd_req = 0;
        s1_rd_enable = 0;
        s1_rd_grant_accept = 0;
        s1_rd_service_valid = 0;
        s1_rd_service_master = 0;
        s1_rd_epoch_clear = 0;

        $display("--------------------------------------");
        $display("READ ARBITER BANK TEST STARTED");
        $display("--------------------------------------");

        repeat (2) @(posedge aclk);
        @(negedge aclk);

        aresetn = 1;

        // TEST 1: Independent arbitration

        s0_rd_enable = 1;
        s1_rd_enable = 1;

        s0_rd_req = 2'b01;
        s1_rd_req = 2'b10;

        check_grants(2'b01, 2'b10,
                     "Independent S0 and S1 grants");

        // Capture both grants during stalls

        @(posedge aclk);
        #1;

        @(negedge aclk);

        s0_rd_req = 2'b11;
        s1_rd_req = 2'b11;

        check_grants(2'b01, 2'b10,
                     "Both grants remain stable during stalls");

        // TEST 3: Disable arbitration while grants are locked.
        // Existing grants must remain stable.

        s0_rd_enable = 0;

        check_grants(2'b01, 2'b10,
                     "Locked grants survive arbitration disable");

        // Release both grants and remove requests together.

        @(negedge aclk);

        s0_rd_grant_accept = 1;
        s1_rd_grant_accept = 1;

        s0_rd_req = 2'b00;
        s1_rd_req = 2'b00;

        @(posedge aclk);
        #1;

        @(negedge aclk);

        s0_rd_grant_accept = 0;
        s1_rd_grant_accept = 0;

        s0_rd_enable = 1;

        check_grants(2'b00, 2'b00,
                     "Both grants released after acceptance");

        // TEST 4: Round-robin initial grants

        arb_policy = 2'b01;

        s0_rd_req = 2'b11;
        s1_rd_req = 2'b10;

        check_grants(2'b01, 2'b10,
                     "Round-robin initial grants");

        // Accept S0's M0 grant.

        @(negedge aclk);
        s0_rd_grant_accept = 1;

        @(posedge aclk);
        #1;

        @(negedge aclk);
        s0_rd_grant_accept = 0;

        // RR should now select M1.

        check_grants(2'b10, 2'b10,
                     "S0 round-robin advances to M1");

        // Complete the newly selected S0 M1 grant.
        // Also release S1's outstanding grant.

        @(negedge aclk);

        s0_rd_grant_accept = 1;
        s1_rd_grant_accept = 1;

        s0_rd_req = 2'b00;
        s1_rd_req = 2'b00;

        @(posedge aclk);
        #1;

        @(negedge aclk);

        s0_rd_grant_accept = 0;
        s1_rd_grant_accept = 0;

        // TEST 5: Reserved policy with no active requests.

        arb_policy = 2'b11;

        check_grants(2'b00, 2'b00,
                     "Reserved policy produces no grants");

        // TEST 6: Both arbitration points disabled.

        arb_policy = 2'b00;
        s0_rd_enable = 0;
        s1_rd_enable = 0;

        s0_rd_req = 2'b11;
        s1_rd_req = 2'b11;

        check_grants(2'b00, 2'b00,
                     "Both arbitration points disabled");

        // Summary

        $display("--------------------------------------");
        $display("TOTAL PASSED: %0d", passed);
        $display("TOTAL FAILED: %0d", failed);

        if (failed == 0)
            $display("ALL READ ARBITER BANK TESTS PASSED!");
        else
            $display("READ ARBITER BANK TESTS FAILED!");

        $display("--------------------------------------");

        $finish;

    end

endmodule
