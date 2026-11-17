`timescale 1ns / 1ps

module tb_read_arbiter_performance;

    // Experiment C configuration
parameter M0_BURST_BEATS = 4;
parameter M1_BURST_BEATS = 4;
parameter TARGET_TXNS    = 20;

    reg aclk;
    reg aresetn;
    reg [1:0] arb_policy;

    // Slave 0 arbitration
    reg [1:0] s0_rd_req;
    wire s0_rd_enable;
    wire s0_rd_grant_accept;
    wire [1:0] s0_rd_grant;

    // Slave 0 service feedback
    wire s0_rd_service_valid;
    wire s0_rd_service_master;

    // Slave 1 remains idle
    wire [1:0] s1_rd_grant;

    // Testbench slave model
    reg busy;
    reg owner;
    integer beat_count;
    integer current_burst_beats;

    // Performance measurements
    integer cycle_count;
    integer accepted0, accepted1;

    integer total_wait0, total_wait1;
    integer max_wait0, max_wait1;

    integer request_start0, request_start1;
    integer wait_value;

    integer service_beats0, service_beats1;

    // Sampling variables
    reg [1:0] selected_grant;
    reg accept_now;

    // Clock: 100 MHz
    initial aclk = 1'b0;
    always #5 aclk = ~aclk;

    // Arbitration and service connections
    assign s0_rd_enable = ~busy;

    assign s0_rd_grant_accept =
        s0_rd_enable && (s0_rd_grant != 2'b00);

    // One successful service beat per busy clock cycle.
    // This model assumes the slave is always ready.
    assign s0_rd_service_valid = busy;
    assign s0_rd_service_master = owner;

    // Actual read arbitration bank
    axi4_crossbar_read_arbiter_bank DUT (

        .aclk(aclk),
        .aresetn(aresetn),

        .arb_policy(arb_policy),

        .s0_rd_req(s0_rd_req),
        .s0_rd_enable(s0_rd_enable),
        .s0_rd_grant_accept(s0_rd_grant_accept),
        .s0_rd_service_valid(s0_rd_service_valid),
        .s0_rd_service_master(s0_rd_service_master),
        .s0_rd_epoch_clear(1'b0),
        .s0_rd_grant(s0_rd_grant),

        .s1_rd_req(2'b00),
        .s1_rd_enable(1'b0),
        .s1_rd_grant_accept(1'b0),
        .s1_rd_service_valid(1'b0),
        .s1_rd_service_master(1'b0),
        .s1_rd_epoch_clear(1'b0),
        .s1_rd_grant(s1_rd_grant)
    );

    // ------------------------------------------------
    // Run one arbitration policy
    // ------------------------------------------------

    task run_policy;

        input [1:0] selected_policy;

        begin

            $display("");
            $display("========================================");
            $display("Starting Policy %b", selected_policy);
            $display("========================================");

            $display("Master 0 Burst Length : %0d beats",
                     M0_BURST_BEATS);

            $display("Master 1 Burst Length : %0d beats",
                     M1_BURST_BEATS);

            $display("Transactions per Master: %0d", TARGET_TXNS);

            // Reset experiment
            aresetn = 1'b0;
            arb_policy = selected_policy;

            s0_rd_req = 2'b00;

            busy = 1'b0;
            owner = 1'b0;

            beat_count = 0;
            current_burst_beats = 0;

            cycle_count = 0;

            accepted0 = 0;
            accepted1 = 0;

            total_wait0 = 0;
            total_wait1 = 0;

            max_wait0 = 0;
            max_wait1 = 0;

            service_beats0 = 0;
            service_beats1 = 0;

            request_start0 = 0;
            request_start1 = 0;

            repeat (4) @(negedge aclk);

            // Start both masters together
            aresetn = 1'b1;
            s0_rd_req = 2'b11;

            request_start0 = cycle_count;
            request_start1 = cycle_count;

            // Run until both masters finish
            while (
                (accepted0 < TARGET_TXNS) ||
                (accepted1 < TARGET_TXNS) ||
                busy
            ) begin

                // Sample grant before sequential updates
                @(posedge aclk);

                selected_grant = s0_rd_grant;

                accept_now =
                    aresetn &&
                    !busy &&
                    (selected_grant != 2'b00);

                #1;

                cycle_count = cycle_count + 1;

                // Watchdog
                if (cycle_count > 100000) begin
                    $display("[ERROR] Simulation watchdog!");
                    $finish;
                end

                // ------------------------------------
                // Address transaction accepted
                // ------------------------------------

                if (accept_now) begin

                    busy = 1'b1;
                    beat_count = 0;

                    if (selected_grant == 2'b01) begin

                        owner = 1'b0;

                        current_burst_beats = M0_BURST_BEATS;

                        wait_value =
                            cycle_count - request_start0;

                        accepted0 = accepted0 + 1;
                        total_wait0 = total_wait0 + wait_value;

                        if (wait_value > max_wait0)
                            max_wait0 = wait_value;

                        s0_rd_req[0] = 1'b0;

                        $display(
                            "[GRANT] Cycle=%0d M0 Wait=%0d Burst=%0d",
                            cycle_count,
                            wait_value,
                            current_burst_beats
                        );

                    end

                    else if (selected_grant == 2'b10) begin

                        owner = 1'b1;

                        current_burst_beats = M1_BURST_BEATS;

                        wait_value =
                            cycle_count - request_start1;

                        accepted1 = accepted1 + 1;
                        total_wait1 = total_wait1 + wait_value;

                        if (wait_value > max_wait1)
                            max_wait1 = wait_value;

                        s0_rd_req[1] = 1'b0;

                        $display(
                            "[GRANT] Cycle=%0d M1 Wait=%0d Burst=%0d",
                            cycle_count,
                            wait_value,
                            current_burst_beats
                        );

                    end

                end

                // ------------------------------------
                // Read data burst service
                // ------------------------------------

                else if (busy) begin

                    beat_count = beat_count + 1;

                    // Count successful service beats
                    if (owner == 1'b0)
                        service_beats0 = service_beats0 + 1;
                    else
                        service_beats1 = service_beats1 + 1;

                    // Finish current burst
                    if (beat_count >= current_burst_beats) begin

                        busy = 1'b0;
                        beat_count = 0;

                        // Request next transaction
                        if (!owner && accepted0 < TARGET_TXNS) begin

                            s0_rd_req[0] = 1'b1;
                            request_start0 = cycle_count;

                        end

                        else if (owner && accepted1 < TARGET_TXNS) begin

                            s0_rd_req[1] = 1'b1;
                            request_start1 = cycle_count;

                        end

                    end

                end

            end

            // ------------------------------------
            // Performance results
            // ------------------------------------

            $display("");
            $display("----------------------------------------");
            $display("PERFORMANCE RESULTS: POLICY %b",
                     selected_policy);
            $display("----------------------------------------");

            $display("Master 0 Transactions : %0d", accepted0);
            $display("Master 1 Transactions : %0d", accepted1);

            $display("Master 0 Burst Length : %0d", M0_BURST_BEATS);
            $display("Master 1 Burst Length : %0d", M1_BURST_BEATS);

            $display("Master 0 Service Beats: %0d", service_beats0);
            $display("Master 1 Service Beats: %0d", service_beats1);

            $display("Master 0 Total Wait   : %0d", total_wait0);
            $display("Master 1 Total Wait   : %0d", total_wait1);

            $display("Master 0 Average Wait : %0d",
                     total_wait0 / TARGET_TXNS);

            $display("Master 1 Average Wait : %0d",
                     total_wait1 / TARGET_TXNS);

            $display("Master 0 Maximum Wait : %0d", max_wait0);
            $display("Master 1 Maximum Wait : %0d", max_wait1);

            $display("Total Execution Cycles: %0d", cycle_count);

            $display("----------------------------------------");

            // Validate expected transaction and beat counts
            if ((accepted0 == TARGET_TXNS) &&
                (accepted1 == TARGET_TXNS) &&
                (service_beats0 == TARGET_TXNS * M0_BURST_BEATS) &&
                (service_beats1 == TARGET_TXNS * M1_BURST_BEATS)) begin

                $display("[PASS] Transaction and service-beat counts verified");

            end
            else begin

                $display("[ERROR] Transaction or service-beat mismatch");

            end

        end

    endtask

    // ------------------------------------------------
    // Main experiment
    // ------------------------------------------------

    initial begin

        aresetn = 1'b0;
        arb_policy = 2'b00;

        s0_rd_req = 2'b00;

        busy = 1'b0;
        owner = 1'b0;

        beat_count = 0;
        current_burst_beats = 0;

        // Fixed Priority
        run_policy(2'b00);

        // Round Robin
        run_policy(2'b01);

        // Burst-Aware Age-Based
        run_policy(2'b10);

        $display("");
        $display("========================================");
        $display("EXPERIMENT C COMPLETED");
        $display("========================================");

        $finish;

    end

endmodule
