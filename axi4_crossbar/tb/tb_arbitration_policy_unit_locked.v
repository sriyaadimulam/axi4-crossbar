
`timescale 1ns / 1ps

module tb_arbitration_policy_unit_locked;

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

    integer passed;
    integer failed;

    arbitration_policy_unit_locked DUT (
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

    // Clock generation: 10 ns period
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    task check_grant;
        input [1:0] expected;
        input [200*8-1:0] test_name;
        begin
            #1;
            if (grant === expected) begin
                $display("PASS: %0s", test_name);
                passed = passed + 1;
            end
            else begin
                $display("FAIL: %0s | Expected=%b Actual=%b",
                         test_name, expected, grant);
                failed = failed + 1;
            end
        end
    endtask

    initial begin

        passed = 0;
        failed = 0;

        aresetn = 0;
        arb_policy = 2'b01;
        req = 2'b00;
        arb_enable = 0;
        grant_accept = 0;
        service_valid = 0;
        service_master = 0;
        epoch_clear = 0;

        $display("-------------------------------------");
        $display("LOCKED ARBITRATION TEST STARTED");
        $display("-------------------------------------");

        // Reset
        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;
        arb_enable = 1;

        // Test 1: M0 is initially selected
        req = 2'b01;
        check_grant(2'b01, "Initial grant selects M0");

        // Allow the lock to capture M0 during the stall
        @(posedge aclk);
        #1;

        // Test 2: M1 requests while M0 is stalled
        req = 2'b11;
        check_grant(2'b01, "Grant remains locked to M0");

        // Test 3: M0 address handshake occurs
        @(negedge aclk);
        grant_accept = 1;

        @(posedge aclk);
        #1;

        grant_accept = 0;

        // Round-robin should now select M1
        check_grant(2'b10, "Round-robin advances to M1 after acceptance");

        // Test 4: M1 is stalled
        @(posedge aclk);
        #1;

        req = 2'b11;
        check_grant(2'b10, "Grant remains locked to M1");

        // Test 5: M1 address handshake occurs
        @(negedge aclk);
        grant_accept = 1;

        @(posedge aclk);
        #1;

        grant_accept = 0;

        // Round-robin should return to M0
        check_grant(2'b01, "Round-robin returns to M0");

        // Summary
        $display("-------------------------------------");
        $display("TOTAL PASSED: %0d", passed);
        $display("TOTAL FAILED: %0d", failed);

        if (failed == 0)
            $display("ALL LOCKED ARBITRATION TESTS PASSED!");
        else
            $display("LOCKED ARBITRATION TESTS FAILED!");

        $display("-------------------------------------");

        $finish;
    end

endmodule
