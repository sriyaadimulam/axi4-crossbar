`timescale 1ns / 1ps

module tb_round_robin_arbiter;

    reg aclk;
    reg aresetn;

    reg [1:0] req;
    reg grant_accept;

    wire [1:0] grant;

    integer errors;

    // Device Under Test
    round_robin_arbiter DUT (
        .aclk         (aclk),
        .aresetn      (aresetn),
        .req          (req),
        .grant_accept (grant_accept),
        .grant        (grant)
    );

    // Clock generation: 10 ns period
    initial begin
        aclk = 1'b0;
        forever #5 aclk = ~aclk;
    end

    // Check grant output
    task check_grant;
        input [1:0] test_req;
        input [1:0] expected_grant;

        begin
            req = test_req;
            #2;

            if (grant !== expected_grant) begin
                $display("FAIL: req=%b expected=%b actual=%b",
                         test_req, expected_grant, grant);
                errors = errors + 1;
            end
            else begin
                $display("PASS: req=%b grant=%b",
                         test_req, grant);
            end
        end
    endtask

    // Accept the currently selected grant
    task accept_current_grant;
        begin
            @(negedge aclk);
            grant_accept = 1'b1;

            @(posedge aclk);
            #1;
            grant_accept = 1'b0;
            #1;
        end
    endtask

    // Test sequence
    initial begin

        errors = 0;
        req = 2'b00;
        grant_accept = 1'b0;
        aresetn = 1'b0;

        $display("====================================");
        $display(" ROUND ROBIN ARBITER TEST STARTED");
        $display("====================================");

        // Reset
        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1'b1;

        // Test 1: No requests
        check_grant(2'b00, 2'b00);

        // Test 2: Only Master 0 requests
        check_grant(2'b01, 2'b01);

        // Test 3: Only Master 1 requests
        check_grant(2'b10, 2'b10);

        // Test 4: Both request; initial priority is M0
        check_grant(2'b11, 2'b01);

        // Test 5: Priority must not change without acceptance
        check_grant(2'b11, 2'b01);

        // Test 6: Accept M0; next priority becomes M1
        accept_current_grant;
        check_grant(2'b11, 2'b10);

        // Test 7: Accept M1; next priority becomes M0
        accept_current_grant;
        check_grant(2'b11, 2'b01);

        // Test 8: Only M1 requests while M0 has priority
        check_grant(2'b10, 2'b10);

        // Accept M1; next priority becomes M0
        accept_current_grant;

        // Test 9: Both request; M0 should win
        check_grant(2'b11, 2'b01);

        $display("====================================");

        if (errors == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("TEST FAILED: %0d errors", errors);

        $display("====================================");

        $finish;

    end

endmodule