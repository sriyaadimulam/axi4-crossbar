
`timescale 1ns / 1ps

module tb_axi4_demo_top;

    reg aclk;
    reg aresetn;
    reg start;
    reg [1:0] arb_policy;

    wire [31:0] m0_transaction_count;
    wire [31:0] m1_transaction_count;

    wire m0_error;
    wire m1_error;
    wire m0_active;
    wire m1_active;

    integer checks;
    integer failures;
    integer timeout_count;

    // ------------------------------------------------
    // CLOCK GENERATION: 100 MHz
    // ------------------------------------------------

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // ------------------------------------------------
    // DUT INSTANTIATION
    // ------------------------------------------------

    axi4_demo_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .ID_WIDTH(4),
        .BURST_BEATS(4)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(start),
        .arb_policy(arb_policy),

        .m0_transaction_count(m0_transaction_count),
        .m1_transaction_count(m1_transaction_count),

        .m0_error(m0_error),
        .m1_error(m1_error),
        .m0_active(m0_active),
        .m1_active(m1_active)
    );

    // ------------------------------------------------
    // CHECK TASK
    // ------------------------------------------------

    task check_result;
        input condition;
        input [8*100-1:0] message;

        begin
            checks = checks + 1;

            if (condition)
                $display("[PASS] %0s", message);
            else begin
                $display("[FAIL] %0s", message);
                failures = failures + 1;
            end
        end
    endtask

    // ------------------------------------------------
    // MAIN TEST
    // ------------------------------------------------

    initial begin

        checks = 0;
        failures = 0;
        timeout_count = 0;

        aresetn = 0;
        start = 0;

        // Arbitration policy:
        // 00 = Fixed Priority
        // 01 = Round Robin
        // 10 = Burst-Aware Age-Based

        arb_policy = 2'b10;

        $display("");
        $display("==========================================");
        $display("       AXI4 CROSSBAR INTEGRATION TEST");
        $display("==========================================");

        $display("Arbitration Policy: BURST-AWARE AGE-BASED (10)");
        $display("Target: 4 transactions per master");

        // --------------------------------------------
        // RESET
        // --------------------------------------------

        repeat (5) @(posedge aclk);

        @(negedge aclk);
        aresetn = 1;

        repeat (3) @(posedge aclk);

        // --------------------------------------------
        // START BOTH MASTERS
        // --------------------------------------------

        @(negedge aclk);

        start = 1;

        $display("");
        $display("[INFO] Both masters started");

        // --------------------------------------------
        // WAIT FOR FOUR TRANSACTIONS PER MASTER
        // --------------------------------------------

        while ((m0_transaction_count < 4 ||
        m1_transaction_count < 4) &&
        timeout_count < 10000) begin

    @(posedge aclk);
    timeout_count = timeout_count + 1;

    if (timeout_count % 1000 == 0)
        $display("M0=%0d M1=%0d Timeout=%0d",
                 m0_transaction_count,
                 m1_transaction_count,
                 timeout_count);
end begin

            @(posedge aclk);

            timeout_count = timeout_count + 1;

        end

        // --------------------------------------------
        // STOP BOTH MASTERS
        // --------------------------------------------

        @(negedge aclk);

        start = 0;

        $display("");
        $display("[INFO] Master start signal deasserted");

        // Allow signals to settle
        repeat (2) @(posedge aclk);

        // --------------------------------------------
        // VERIFICATION
        // --------------------------------------------

        check_result(
            m0_active,
            "Master 0 started"
        );

        check_result(
            m1_active,
            "Master 1 started"
        );

        check_result(
            m0_transaction_count >= 4,
            "Master 0 completed four transactions"
        );

        check_result(
            m1_transaction_count >= 4,
            "Master 1 completed four transactions"
        );

        check_result(
            !m0_error,
            "Master 0 has no AXI errors"
        );

        check_result(
            !m1_error,
            "Master 1 has no AXI errors"
        );

        check_result(
            timeout_count < 10000,
            "No integration timeout detected"
        );

        // --------------------------------------------
        // FINAL SUMMARY
        // --------------------------------------------

        $display("");
        $display("==========================================");
        $display("              TEST SUMMARY");
        $display("==========================================");

        $display("Arbitration Policy : %b", arb_policy);

        $display("Checks Run         : %0d", checks);
        $display("Failures           : %0d", failures);

        $display("M0 Transactions    : %0d",
                 m0_transaction_count);

        $display("M1 Transactions    : %0d",
                 m1_transaction_count);

        $display("M0 Error           : %b", m0_error);
        $display("M1 Error           : %b", m1_error);

        $display("Timeout Cycles     : %0d", timeout_count);

        $display("------------------------------------------");

        if (failures == 0)
            $display("INTEGRATION TESTS PASSED");
        else
            $display("INTEGRATION TESTS FAILED");

        $display("==========================================");

        $finish;

    end

    // ------------------------------------------------
    // GLOBAL WATCHDOG
    // ------------------------------------------------

    initial begin

        #2000000;

        $display("");
        $display("[FAIL] GLOBAL SIMULATION TIMEOUT");

        $finish;

    end

endmodule
