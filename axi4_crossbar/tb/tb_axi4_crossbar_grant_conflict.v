
`timescale 1ns / 1ps

module tb_axi4_crossbar_grant_conflict;

    reg [1:0] s0_grant;
    reg [1:0] s1_grant;

    reg s0_enable;
    reg s1_enable;

    wire [1:0] s0_final_grant;
    wire [1:0] s1_final_grant;

    wire s0_final_enable;
    wire s1_final_enable;

    wire m0_conflict;
    wire m1_conflict;

    integer pass_count;
    integer fail_count;

    axi4_crossbar_grant_conflict dut (
        .s0_grant(s0_grant),
        .s1_grant(s1_grant),

        .s0_enable(s0_enable),
        .s1_enable(s1_enable),

        .s0_final_grant(s0_final_grant),
        .s1_final_grant(s1_final_grant),

        .s0_final_enable(s0_final_enable),
        .s1_final_enable(s1_final_enable),

        .m0_conflict(m0_conflict),
        .m1_conflict(m1_conflict)
    );

    task check;
        input condition;
        input [8*100-1:0] test_name;
        begin
            if (condition) begin
                $display("PASS: %0s", test_name);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        s0_grant = 0;
        s1_grant = 0;
        s0_enable = 0;
        s1_enable = 0;

        $display("AXI4 CROSSBAR GRANT CONFLICT TEST STARTED");

        // Test 1: Both slaves request M0
        s0_grant = 2'b01;
        s1_grant = 2'b01;
        s0_enable = 1;
        s1_enable = 1;
        #1;

        check(s0_final_grant == 2'b01 &&
              s0_final_enable,
              "S0 retains M0 grant");

        check(s1_final_grant == 2'b00 &&
              !s1_final_enable,
              "S1 M0 conflict suppressed");

        check(m0_conflict && !m1_conflict,
              "M0 conflict detected");

        // Test 2: Both slaves request M1
        s0_grant = 2'b10;
        s1_grant = 2'b10;
        #1;

        check(s0_final_grant == 2'b10 &&
              s0_final_enable,
              "S0 retains M1 grant");

        check(s1_final_grant == 2'b00 &&
              !s1_final_enable,
              "S1 M1 conflict suppressed");

        check(m1_conflict && !m0_conflict,
              "M1 conflict detected");

        // Test 3: Different masters selected
        s0_grant = 2'b01;
        s1_grant = 2'b10;
        #1;

        check(s0_final_grant == 2'b01 &&
              s1_final_grant == 2'b10 &&
              s0_final_enable && s1_final_enable,
              "Different masters granted simultaneously");

        check(!m0_conflict && !m1_conflict,
              "No conflict for different masters");

        // Test 4: Opposite different-master selection
        s0_grant = 2'b10;
        s1_grant = 2'b01;
        #1;

        check(s0_final_grant == 2'b10 &&
              s1_final_grant == 2'b01 &&
              s0_final_enable && s1_final_enable,
              "Reverse different-master grants accepted");

        // Test 5: S0 disabled
        s0_enable = 0;
        s1_enable = 1;
        s0_grant = 2'b00;
        s1_grant = 2'b01;
        #1;

        check(!s0_final_enable &&
              s1_final_enable &&
              s1_final_grant == 2'b01,
              "S1 operates when S0 is disabled");

        // Test 6: S1 disabled
        s0_enable = 1;
        s1_enable = 0;
        s0_grant = 2'b10;
        s1_grant = 2'b00;
        #1;

        check(s0_final_enable &&
              !s1_final_enable &&
              s0_final_grant == 2'b10,
              "S0 operates when S1 is disabled");

        // Test 7: Both disabled
        s0_enable = 0;
        s1_enable = 0;
        s0_grant = 0;
        s1_grant = 0;
        #1;

        check(!s0_final_enable &&
              !s1_final_enable &&
              s0_final_grant == 0 &&
              s1_final_grant == 0,
              "Both arbitration points disabled");

        // Test 8: No grant from S0
        s0_enable = 1;
        s1_enable = 1;
        s0_grant = 0;
        s1_grant = 2'b01;
        #1;

        check(s0_final_enable &&
              s1_final_enable &&
              s1_final_grant == 2'b01,
              "S1 grant accepted when S0 has no grant");

        // Final result
        $display("----------------------------------");
        $display("TOTAL PASSED: %0d", pass_count);
        $display("TOTAL FAILED: %0d", fail_count);

        if (fail_count == 0)
            $display("ALL GRANT CONFLICT TESTS PASSED!");
        else
            $display("GRANT CONFLICT TESTS FAILED!");

        $finish;
    end

endmodule
