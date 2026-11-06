
`timescale 1ns / 1ps

module tb_axi4_crossbar_arbiter_bank;

    reg aclk;
    reg aresetn;
    reg [1:0] arb_policy;

    reg [1:0] s0_rd_req, s0_wr_req;
    reg [1:0] s1_rd_req, s1_wr_req;

    reg s0_rd_enable, s0_wr_enable;
    reg s1_rd_enable, s1_wr_enable;

    reg s0_rd_grant_accept, s0_wr_grant_accept;
    reg s1_rd_grant_accept, s1_wr_grant_accept;

    reg s0_rd_service_valid, s0_wr_service_valid;
    reg s1_rd_service_valid, s1_wr_service_valid;

    reg s0_rd_service_master, s0_wr_service_master;
    reg s1_rd_service_master, s1_wr_service_master;

    reg s0_rd_epoch_clear, s0_wr_epoch_clear;
    reg s1_rd_epoch_clear, s1_wr_epoch_clear;

    wire [1:0] s0_rd_grant, s0_wr_grant;
    wire [1:0] s1_rd_grant, s1_wr_grant;

    integer errors;

    axi4_crossbar_arbiter_bank DUT (
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

        .s0_wr_req(s0_wr_req),
        .s0_wr_enable(s0_wr_enable),
        .s0_wr_grant_accept(s0_wr_grant_accept),
        .s0_wr_service_valid(s0_wr_service_valid),
        .s0_wr_service_master(s0_wr_service_master),
        .s0_wr_epoch_clear(s0_wr_epoch_clear),
        .s0_wr_grant(s0_wr_grant),

        .s1_rd_req(s1_rd_req),
        .s1_rd_enable(s1_rd_enable),
        .s1_rd_grant_accept(s1_rd_grant_accept),
        .s1_rd_service_valid(s1_rd_service_valid),
        .s1_rd_service_master(s1_rd_service_master),
        .s1_rd_epoch_clear(s1_rd_epoch_clear),
        .s1_rd_grant(s1_rd_grant),

        .s1_wr_req(s1_wr_req),
        .s1_wr_enable(s1_wr_enable),
        .s1_wr_grant_accept(s1_wr_grant_accept),
        .s1_wr_service_valid(s1_wr_service_valid),
        .s1_wr_service_master(s1_wr_service_master),
        .s1_wr_epoch_clear(s1_wr_epoch_clear),
        .s1_wr_grant(s1_wr_grant)
    );

    // 100 MHz clock
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    task check_grants;
        input [1:0] exp_s0_rd;
        input [1:0] exp_s0_wr;
        input [1:0] exp_s1_rd;
        input [1:0] exp_s1_wr;
        input [255:0] test_name;

        begin
            #1;

            if ((s0_rd_grant !== exp_s0_rd) ||
                (s0_wr_grant !== exp_s0_wr) ||
                (s1_rd_grant !== exp_s1_rd) ||
                (s1_wr_grant !== exp_s1_wr)) begin

                $display("FAIL: %s", test_name);
                $display("Expected: S0RD=%b S0WR=%b S1RD=%b S1WR=%b",
                         exp_s0_rd, exp_s0_wr, exp_s1_rd, exp_s1_wr);
                $display("Actual:   S0RD=%b S0WR=%b S1RD=%b S1WR=%b",
                         s0_rd_grant, s0_wr_grant,
                         s1_rd_grant, s1_wr_grant);

                errors = errors + 1;
            end
            else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin

        errors = 0;

        aresetn = 0;
        arb_policy = 2'b00;

        s0_rd_req = 0;
        s0_wr_req = 0;
        s1_rd_req = 0;
        s1_wr_req = 0;

        s0_rd_enable = 0;
        s0_wr_enable = 0;
        s1_rd_enable = 0;
        s1_wr_enable = 0;

        s0_rd_grant_accept = 0;
        s0_wr_grant_accept = 0;
        s1_rd_grant_accept = 0;
        s1_wr_grant_accept = 0;

        s0_rd_service_valid = 0;
        s0_wr_service_valid = 0;
        s1_rd_service_valid = 0;
        s1_wr_service_valid = 0;

        s0_rd_service_master = 0;
        s0_wr_service_master = 0;
        s1_rd_service_master = 0;
        s1_wr_service_master = 0;

        s0_rd_epoch_clear = 0;
        s0_wr_epoch_clear = 0;
        s1_rd_epoch_clear = 0;
        s1_wr_epoch_clear = 0;

        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        $display("\nCROSSBAR ARBITER BANK TEST STARTED\n");

        // =====================================
        // TEST 1: All four points, fixed policy
        // =====================================

        arb_policy = 2'b00;

        s0_rd_enable = 1;
        s0_wr_enable = 1;
        s1_rd_enable = 1;
        s1_wr_enable = 1;

        s0_rd_req = 2'b11;
        s0_wr_req = 2'b11;
        s1_rd_req = 2'b11;
        s1_wr_req = 2'b11;

        check_grants(2'b01, 2'b01, 2'b01, 2'b01,
                     "All four points grant M0");

        // =====================================
        // TEST 2: Independent requests
        // =====================================

        s0_rd_req = 2'b01;
        s0_wr_req = 2'b10;
        s1_rd_req = 2'b11;
        s1_wr_req = 2'b00;

        check_grants(2'b01, 2'b10, 2'b01, 2'b00,
                     "Independent grants at all points");

        // =====================================
        // TEST 3: Independent enable signals
        // =====================================

        s0_rd_enable = 0;
        s0_wr_enable = 1;
        s1_rd_enable = 1;
        s1_wr_enable = 0;

        check_grants(2'b00, 2'b10, 2'b01, 2'b00,
                     "Independent arbitration enables");

        // =====================================
        // TEST 4: Round-robin independence
        // =====================================

        arb_policy = 2'b01;

        s0_rd_enable = 1;
        s0_wr_enable = 1;
        s1_rd_enable = 1;
        s1_wr_enable = 1;

        s0_rd_req = 2'b11;
        s0_wr_req = 2'b11;
        s1_rd_req = 2'b11;
        s1_wr_req = 2'b11;

        check_grants(2'b01, 2'b01, 2'b01, 2'b01,
                     "RR initial grants");

        // Accept only S0 read grant for M0
        @(negedge aclk);
        s0_rd_grant_accept = 1;

        @(negedge aclk);
        s0_rd_grant_accept = 0;

        check_grants(2'b10, 2'b01, 2'b01, 2'b01,
                     "Only S0 read RR priority changes");

        // =====================================
        // TEST 5: Reserved policy
        // =====================================

        arb_policy = 2'b11;

        check_grants(2'b00, 2'b00, 2'b00, 2'b00,
                     "Reserved policy gives no grants");

        // =====================================
        // RESULTS
        // =====================================

        if (errors == 0)
            $display("\nALL ARBITER BANK TESTS PASSED!");
        else
            $display("\nTEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
