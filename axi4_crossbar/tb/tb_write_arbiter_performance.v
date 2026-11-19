`timescale 1ns / 1ps

module tb_write_arbiter_performance;

    //================================================
    // CLOCK AND RESET
    //================================================

    reg aclk;
    reg aresetn;

    reg [1:0] arb_policy;

    initial begin
        aclk = 1'b0;
        forever #5 aclk = ~aclk;
    end

    //================================================
    // PERFORMANCE CONFIGURATION
    //================================================

    parameter M0_BURST_BEATS = 4;
    parameter M1_BURST_BEATS = 4;
    parameter TARGET_TXNS    = 20;

    parameter M0_GAP_CYCLES = 0;
    parameter M1_GAP_CYCLES = 4;

    //================================================
    // GLOBAL CYCLE COUNTER
    //================================================

    integer cycle_count;

    always @(posedge aclk) begin
        if (!aresetn)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

    //================================================
    // SLAVE 0 WRITE ARBITRATION SIGNALS
    //================================================

    reg [1:0] s0_wr_req;
    reg s0_wr_enable;
    reg s0_wr_grant_accept;
    reg s0_wr_service_valid;
    reg s0_wr_service_master;
    reg s0_wr_epoch_clear;

    wire [1:0] s0_wr_grant;

    //================================================
    // SLAVE 1 WRITE ARBITRATION SIGNALS
    //================================================

    reg [1:0] s1_wr_req;
    reg s1_wr_enable;
    reg s1_wr_grant_accept;
    reg s1_wr_service_valid;
    reg s1_wr_service_master;
    reg s1_wr_epoch_clear;

    wire [1:0] s1_wr_grant;

    //================================================
    // PERFORMANCE MEASUREMENT VARIABLES
    //================================================

    integer accepted0;
    integer accepted1;

    integer total_wait0;
    integer total_wait1;

    integer max_wait0;
    integer max_wait1;

    integer wait_value;

    integer service_beats0;
    integer service_beats1;

    //================================================
    // SIMPLIFIED WRITE SERVICE MODEL
    //================================================

    reg busy;
    reg owner;

    integer beat_count;
    integer current_burst;

    //================================================
    // INITIALIZE SIGNALS
    //================================================

    task initialize_signals;
        begin
            aresetn = 1'b0;
            arb_policy = 2'b00;

            s0_wr_req = 2'b00;
            s1_wr_req = 2'b00;

            s0_wr_enable = 1'b0;
            s1_wr_enable = 1'b0;

            s0_wr_grant_accept = 1'b0;
            s1_wr_grant_accept = 1'b0;

            s0_wr_service_valid = 1'b0;
            s1_wr_service_valid = 1'b0;

            s0_wr_service_master = 1'b0;
            s1_wr_service_master = 1'b0;

            s0_wr_epoch_clear = 1'b0;
            s1_wr_epoch_clear = 1'b0;

            busy = 1'b0;
            owner = 1'b0;

            beat_count = 0;
            current_burst = 0;

            accepted0 = 0;
            accepted1 = 0;

            total_wait0 = 0;
            total_wait1 = 0;

            max_wait0 = 0;
            max_wait1 = 0;

            wait_value = 0;

            service_beats0 = 0;
            service_beats1 = 0;
        end
    endtask

    //================================================
    // RESET ARBITRATION BANK
    //================================================

    task reset_bank;
        begin
            @(negedge aclk);

            aresetn = 1'b0;

            s0_wr_req = 2'b00;
            s1_wr_req = 2'b00;

            s0_wr_enable = 1'b0;
            s1_wr_enable = 1'b0;

            s0_wr_grant_accept = 1'b0;
            s1_wr_grant_accept = 1'b0;

            s0_wr_service_valid = 1'b0;
            s1_wr_service_valid = 1'b0;

            s0_wr_service_master = 1'b0;
            s1_wr_service_master = 1'b0;

            s0_wr_epoch_clear = 1'b0;
            s1_wr_epoch_clear = 1'b0;

            busy = 1'b0;
            owner = 1'b0;

            beat_count = 0;
            current_burst = 0;

            repeat (2) @(posedge aclk);

            @(negedge aclk);

            aresetn = 1'b1;
        end
    endtask

    //================================================
    // SIMULATE WRITE BURST AND B RESPONSE
    //================================================

    task service_write_burst;

        input selected_master;
        input integer burst_length;

        integer beat;

        begin

            busy = 1'b1;
            owner = selected_master;

            current_burst = burst_length;
            beat_count = 0;

            // Simulate accepted W data beats
            for (beat = 0; beat < burst_length;
                 beat = beat + 1) begin

                @(negedge aclk);

                s0_wr_service_valid = 1'b1;
                s0_wr_service_master = selected_master;

                @(posedge aclk);

                if (selected_master == 1'b0)
                    service_beats0 = service_beats0 + 1;
                else
                    service_beats1 = service_beats1 + 1;

                beat_count = beat_count + 1;

            end

            // End W-channel transfer
            @(negedge aclk);

            s0_wr_service_valid = 1'b0;

            // Simulate B-channel response completion
            @(posedge aclk);

            @(negedge aclk);

            // Release write slot
            busy = 1'b0;

            s0_wr_enable = 1'b1;

            beat_count = 0;
            current_burst = 0;

        end

    endtask

    //================================================
    // RUN WRITE TRANSACTIONS
    //================================================

    task run_write_transactions;

        input [1:0] policy;

        integer start_cycle0;
        integer start_cycle1;

        integer selected_master;
        integer burst_length;

        begin

            arb_policy = policy;

            accepted0 = 0;
            accepted1 = 0;

            total_wait0 = 0;
            total_wait1 = 0;

            max_wait0 = 0;
            max_wait1 = 0;

            service_beats0 = 0;
            service_beats1 = 0;

            busy = 1'b0;

            s0_wr_req = 2'b11;
            s0_wr_enable = 1'b1;
            s0_wr_grant_accept = 1'b0;

            // Both requests arrive together
            start_cycle0 = cycle_count;
            start_cycle1 = cycle_count;

            while ((accepted0 < TARGET_TXNS) ||
                   (accepted1 < TARGET_TXNS)) begin

                // Wait for arbitration opportunity
                @(negedge aclk);

                s0_wr_enable = !busy;
                s0_wr_grant_accept = 1'b0;

                @(posedge aclk);

                #1;

                // Check for a valid grant
                if (!busy &&
                    (s0_wr_grant != 2'b00)) begin

                    if (s0_wr_grant[0])
                        selected_master = 0;
                    else
                        selected_master = 1;

                    if (selected_master == 0)
                        burst_length = M0_BURST_BEATS;
                    else
                        burst_length = M1_BURST_BEATS;

            // Accept the locked grant
            @(negedge aclk);

            // Keep arbitration enabled during acceptance
            s0_wr_enable = 1'b1;
            s0_wr_grant_accept = 1'b1;

            // Actual grant-accept edge
            @(posedge aclk);

            #1;

            // Now occupy the write slot
            s0_wr_grant_accept = 1'b0;
            busy = 1'b1;
            s0_wr_enable = 1'b0;

                // Measure AW waiting time at acceptance
                    if (selected_master == 0) begin

                        wait_value =
                            cycle_count - start_cycle0;

                        accepted0 = accepted0 + 1;

                        total_wait0 =
                            total_wait0 + wait_value;

                        if (wait_value > max_wait0)
                            max_wait0 = wait_value;

                        s0_wr_req[0] = 1'b0;

                    end
                    else begin

                        wait_value =
                            cycle_count - start_cycle1;

                        accepted1 = accepted1 + 1;

                        total_wait1 =
                            total_wait1 + wait_value;

                        if (wait_value > max_wait1)
                            max_wait1 = wait_value;

                        s0_wr_req[1] = 1'b0;

                    end

                    // Transfer W burst and complete B response
                    service_write_burst(
                        selected_master,
                        burst_length
                    );

                    // Generate next request for Master 0
if ((selected_master == 0) &&
    (accepted0 < TARGET_TXNS)) begin

    repeat (M0_GAP_CYCLES)
        @(posedge aclk);

    @(negedge aclk);

    s0_wr_req[0] = 1'b1;
    start_cycle0 = cycle_count;

end

// Generate next request for Master 1
if ((selected_master == 1) &&
    (accepted1 < TARGET_TXNS)) begin

    repeat (M1_GAP_CYCLES)
        @(posedge aclk);

    @(negedge aclk);

    s0_wr_req[1] = 1'b1;
    start_cycle1 = cycle_count;

end

                end

            end

        end

    endtask

    //================================================
    // DISPLAY PERFORMANCE RESULTS
    //================================================

    task print_results;

        input [8*32-1:0] policy_name;

        begin

            $display("\n--------------------------------------");
            $display("Policy: %0s", policy_name);
            $display("--------------------------------------");

            $display("Master 0:");
            $display("  Accepted transactions : %0d", accepted0);
            $display("  Total AW wait cycles  : %0d", total_wait0);

            $display("  Average AW wait       : %0f",
                (accepted0 != 0) ?
                (1.0 * total_wait0 / accepted0) : 0.0);

            $display("  Maximum AW wait       : %0d", max_wait0);
            $display("  W service beats       : %0d", service_beats0);

            $display("\nMaster 1:");
            $display("  Accepted transactions : %0d", accepted1);
            $display("  Total AW wait cycles  : %0d", total_wait1);

            $display("  Average AW wait       : %0f",
                (accepted1 != 0) ?
                (1.0 * total_wait1 / accepted1) : 0.0);

            $display("  Maximum AW wait       : %0d", max_wait1);
            $display("  W service beats       : %0d", service_beats1);

            $display("\nTotal execution cycles  : %0d", cycle_count);

            $display("--------------------------------------");

        end

    endtask

    //================================================
    // DUT: WRITE ARBITER BANK
    //================================================

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

    //================================================
    // MAIN TEST SEQUENCE
    //================================================

    initial begin

        initialize_signals();

        reset_bank();

        $display("\n======================================");
        $display(" WRITE ARBITRATION PERFORMANCE TEST");
        $display("======================================");

        // Policy 00: Fixed Priority
        $display("\nTesting Fixed Priority...");

        reset_bank();

        run_write_transactions(2'b00);

        print_results("FIXED PRIORITY");

        // Policy 01: Round Robin
        $display("\nTesting Round Robin...");

        reset_bank();

        run_write_transactions(2'b01);

        print_results("ROUND ROBIN");

        // Policy 10: Burst-Aware Age-Based
        $display("\nTesting Burst-Aware...");

        reset_bank();

        run_write_transactions(2'b10);

        print_results("BURST-AWARE AGE-BASED");

        $display("\n======================================");
        $display(" WRITE PERFORMANCE TEST COMPLETED");
        $display("======================================");

        $finish;

    end

    //================================================
    // SIMULATION WATCHDOG
    //================================================

    initial begin

        #1000000;

        $display("\nERROR: Simulation timeout!");

        $finish;

    end

endmodule
