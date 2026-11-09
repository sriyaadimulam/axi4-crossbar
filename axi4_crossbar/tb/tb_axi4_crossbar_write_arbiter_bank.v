
`timescale 1ns / 1ps

module tb_axi4_crossbar_write_arbiter_bank;

    reg aclk;
    reg aresetn;
    reg [1:0] arb_policy;

    reg [1:0] s0_wr_req;
    reg s0_wr_enable;
    reg s0_wr_grant_accept;
    reg s0_wr_service_valid;
    reg s0_wr_service_master;
    reg s0_wr_epoch_clear;
    wire [1:0] s0_wr_grant;

    reg [1:0] s1_wr_req;
    reg s1_wr_enable;
    reg s1_wr_grant_accept;
    reg s1_wr_service_valid;
    reg s1_wr_service_master;
    reg s1_wr_epoch_clear;
    wire [1:0] s1_wr_grant;

    integer pass_count;
    integer fail_count;

    axi4_crossbar_write_arbiter_bank DUT (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        .s0_wr_req(s0_wr_req),
        .s0_wr_enable(s0_wr_enable),
        .s0_wr_grant_accept(s0_wr_grant_accept),
        .s0_wr_service_valid(s0_wr_service_valid),
        .s0_wr_service_master(s0_wr_service_master),
        .s0_wr_epoch_clear(s0_wr_epoch_clear),
        .s0_wr_grant(s0_wr_grant),

        .s1_wr_req(s1_wr_req),
        .s1_wr_enable(s1_wr_enable),
        .s1_wr_grant_accept(s1_wr_grant_accept),
        .s1_wr_service_valid(s1_wr_service_valid),
        .s1_wr_service_master(s1_wr_service_master),
        .s1_wr_epoch_clear(s1_wr_epoch_clear),
        .s1_wr_grant(s1_wr_grant)
    );

    // Clock generation
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // Check expected grants
    task check_grants;
        input [1:0] expected_s0;
        input [1:0] expected_s1;
        input [8*60-1:0] test_name;

        begin
            #1;

            if ((s0_wr_grant === expected_s0) &&
                (s1_wr_grant === expected_s1)) begin

                $display("PASS: %0s | S0=%b S1=%b",
                         test_name, s0_wr_grant, s1_wr_grant);

                pass_count = pass_count + 1;
            end
            else begin

                $display("FAIL: %0s | Expected S0=%b S1=%b, Got S0=%b S1=%b",
                         test_name, expected_s0, expected_s1,
                         s0_wr_grant, s1_wr_grant);

                fail_count = fail_count + 1;
            end
        end
    endtask

    // Reset all arbitration state between independent scenarios
    task reset_bank;
        begin
            @(negedge aclk);

            aresetn = 0;

            s0_wr_req = 0;
            s1_wr_req = 0;

            s0_wr_enable = 0;
            s1_wr_enable = 0;

            s0_wr_grant_accept = 0;
            s1_wr_grant_accept = 0;

            s0_wr_service_valid = 0;
            s1_wr_service_valid = 0;

            s0_wr_service_master = 0;
            s1_wr_service_master = 0;

            s0_wr_epoch_clear = 0;
            s1_wr_epoch_clear = 0;

            repeat (2) @(posedge aclk);
            @(negedge aclk);

            aresetn = 1;
            #1;
        end
    endtask

    initial begin

        pass_count = 0;
        fail_count = 0;

        aclk = 0;
        aresetn = 0;
        arb_policy = 2'b00;

        s0_wr_req = 0;
        s1_wr_req = 0;

        s0_wr_enable = 0;
        s1_wr_enable = 0;

        s0_wr_grant_accept = 0;
        s1_wr_grant_accept = 0;

        s0_wr_service_valid = 0;
        s1_wr_service_valid = 0;

        s0_wr_service_master = 0;
        s1_wr_service_master = 0;

        s0_wr_epoch_clear = 0;
        s1_wr_epoch_clear = 0;

        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        $display("==============================================");
        $display(" WRITE ARBITER BANK TEST STARTED");
        $display("==============================================");

        // TEST 1: No requests
        s0_wr_enable = 1;
        s1_wr_enable = 1;

        check_grants(2'b00, 2'b00, "No requests");

        // TEST 2: Both arbitration points select M0.
        // Independent-bank unit test; not an actual legal
        // simultaneous AW request from one master.
        reset_bank();

        s0_wr_enable = 1;
        s1_wr_enable = 1;
        s0_wr_req = 2'b01;
        s1_wr_req = 2'b01;

        check_grants(2'b01, 2'b01,
                     "Independent S0 and S1 select M0");

        // TEST 3: Both arbitration points select M1
        reset_bank();

        s0_wr_enable = 1;
        s1_wr_enable = 1;
        s0_wr_req = 2'b10;
        s1_wr_req = 2'b10;

        check_grants(2'b10, 2'b10,
                     "Independent S0 and S1 select M1");

        // TEST 4: Different masters simultaneously
        reset_bank();

        s0_wr_enable = 1;
        s1_wr_enable = 1;
        s0_wr_req = 2'b01;
        s1_wr_req = 2'b10;

        check_grants(2'b01, 2'b10,
                     "Different masters granted independently");

        // TEST 5: S0 disabled
        reset_bank();

        s0_wr_enable = 0;
        s1_wr_enable = 1;
        s0_wr_req = 2'b01;
        s1_wr_req = 2'b01;

        check_grants(2'b00, 2'b01,
                     "S1 operates when S0 disabled");

        // TEST 6: S1 disabled
        reset_bank();

        s0_wr_enable = 1;
        s1_wr_enable = 0;
        s0_wr_req = 2'b10;
        s1_wr_req = 2'b10;

        check_grants(2'b10, 2'b00,
                     "S0 operates when S1 disabled");

        // TEST 7: Both arbitration points disabled
        reset_bank();

        s0_wr_enable = 0;
        s1_wr_enable = 0;
        s0_wr_req = 2'b11;
        s1_wr_req = 2'b11;

        check_grants(2'b00, 2'b00,
                     "Both arbitration points disabled");

        // TEST 8: S0 grant remains stable under backpressure
        reset_bank();

        s0_wr_enable = 1;
        s0_wr_req = 2'b01;
        s0_wr_grant_accept = 0;

        check_grants(2'b01, 2'b00,
                     "S0 initial grant");

        @(posedge aclk);
        #1;

        check_grants(2'b01, 2'b00,
                     "S0 grant held during backpressure");

        // Accept the grant
        @(negedge aclk);
        s0_wr_grant_accept = 1;

        @(posedge aclk);
        #1;

        @(negedge aclk);
        s0_wr_grant_accept = 0;
        s0_wr_req = 0;

        check_grants(2'b00, 2'b00,
                     "S0 grant released after acceptance");

        // TEST 9: Round-robin arbitration
        reset_bank();

        arb_policy = 2'b01;
        s0_wr_enable = 1;
        s0_wr_req = 2'b11;

        check_grants(2'b01, 2'b00,
                     "Round robin initial M0 grant");

        // Accept M0 grant
        @(negedge aclk);
        s0_wr_grant_accept = 1;

        @(posedge aclk);
        #1;

        // Next grant should be M1
        @(negedge aclk);
        s0_wr_grant_accept = 0;

        check_grants(2'b10, 2'b00,
                     "Round robin advances to M1");

        // TEST 10: Reserved policy after a clean reset
        reset_bank();

        arb_policy = 2'b11;
        s0_wr_enable = 1;
        s1_wr_enable = 1;
        s0_wr_req = 2'b11;
        s1_wr_req = 2'b11;

        check_grants(2'b00, 2'b00,
                     "Reserved policy produces no grant");

        // Summary
        $display("----------------------------------------------");
        $display(" WRITE ARBITER BANK TEST SUMMARY");
        $display(" PASSED : %0d", pass_count);
        $display(" FAILED : %0d", fail_count);
        $display("----------------------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        #20;
        $finish;

    end

endmodule
