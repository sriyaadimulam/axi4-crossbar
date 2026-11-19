`timescale 1ns / 1ps

module tb_write_arbiter_performance_C;

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
    // EXPERIMENT CONFIGURATION
    //================================================

    parameter M0_BURST_BEATS = 4;
    parameter M1_BURST_BEATS = 4;

    parameter TARGET_TXNS = 20;

    parameter M0_GAP_CYCLES = 0;
    parameter M1_GAP_CYCLES = 4;
    parameter [1:0] TEST_POLICY = 2'b10;


    //================================================
    // INDEPENDENT MASTER REQUEST SIGNALS
    //================================================

    reg [1:0] s0_wr_req;

    // Arbitration acceptance notifications
    reg m0_aw_accepted;
    reg m1_aw_accepted;

    // Write transaction completion notifications
    reg m0_write_done;
    reg m1_write_done;

    // Transaction counters
    integer m0_txn_count;
    integer m1_txn_count;

        // Request arrival timestamps
    integer m0_req_start_cycle;
    integer m1_req_start_cycle;

    // AW waiting-time statistics
    integer m0_wait_total;
    integer m1_wait_total;

    integer m0_wait_max;
    integer m1_wait_max;

    integer m0_wait_current;
    integer m1_wait_current;

    // Accepted transaction counts
    integer m0_aw_count;
    integer m1_aw_count;

    // Accepted W service beats
    integer m0_service_beats;
    integer m1_service_beats;
    integer contention_cycles;

    //================================================
    // GLOBAL EXECUTION COUNTER
    //================================================

    integer cycle_count;

    always @(posedge aclk) begin
        if (!aresetn)
            cycle_count <= 0;
        else
            cycle_count <= cycle_count + 1;
    end

//================================================
// CONTENTION MONITOR
//================================================

always @(posedge aclk) begin
    if (!aresetn)
        contention_cycles <= 0;
    else if (s0_wr_req == 2'b11)
        contention_cycles <= contention_cycles + 1;
end



//================================================
// INITIALIZE TESTBENCH SIGNALS
//================================================

task initialize_signals;
    begin
        aresetn = 1'b0;
        arb_policy = TEST_POLICY;

        s0_wr_req = 2'b00;

        m0_aw_accepted = 1'b0;
        m1_aw_accepted = 1'b0;

        m0_write_done = 1'b0;
        m1_write_done = 1'b0;

        m0_txn_count = 0;
        m1_txn_count = 0;

        cycle_count = 0;
                m0_req_start_cycle = 0;
        m1_req_start_cycle = 0;

        m0_wait_total = 0;
        m1_wait_total = 0;

        m0_wait_max = 0;
        m1_wait_max = 0;

        m0_wait_current = 0;
        m1_wait_current = 0;

        m0_aw_count = 0;
        m1_aw_count = 0;

        m0_service_beats = 0;
        m1_service_beats = 0;
        contention_cycles = 0;
    end
endtask
   
   //================================================
// WRITE ARBITRATION BANK
//================================================

reg s0_wr_enable;
reg s0_wr_grant_accept;
wire [1:0] s0_wr_grant;

reg s1_wr_enable;
reg s1_wr_grant_accept;
wire [1:0] s1_wr_grant;

reg s0_wr_service_valid;
reg s0_wr_service_master;

reg s1_wr_service_valid;
reg [1:0] s1_wr_service_master;

axi4_crossbar_write_arbiter_bank DUT (
    .aclk                 (aclk),
    .aresetn              (aresetn),
    .arb_policy           (arb_policy),

    .s0_wr_req            (s0_wr_req),
    .s0_wr_enable         (s0_wr_enable),
    .s0_wr_grant          (s0_wr_grant),
    .s0_wr_grant_accept   (s0_wr_grant_accept),

    .s1_wr_req            (2'b00),
    .s1_wr_enable         (s1_wr_enable),
    .s1_wr_grant          (s1_wr_grant),
    .s1_wr_grant_accept   (s1_wr_grant_accept),

    .s0_wr_service_valid  (s0_wr_service_valid),
    .s0_wr_service_master (s0_wr_service_master),
    .s0_wr_epoch_clear    (1'b0),

    .s1_wr_service_valid  (s1_wr_service_valid),
    .s1_wr_service_master (s1_wr_service_master),
    .s1_wr_epoch_clear    (1'b0)
);

    //================================================
// WRITE SLOT CONTROLLER
//================================================

reg [1:0] active_owner;
integer active_beats;
integer beat_index;


//------------------------------------------------
// WRITE BURST SERVICE MODEL
//------------------------------------------------

task serve_write_burst;
    input [1:0] owner;
    input integer beats;

    begin
        active_beats = beats;

        for (beat_index = 0;
             beat_index < active_beats;
             beat_index = beat_index + 1) begin

            @(negedge aclk);

            s0_wr_service_valid  = 1'b1;
            if (owner == 2'b01)
        s0_wr_service_master = 1'b0;
    else
        s0_wr_service_master = 1'b1;

            @(posedge aclk);
            #1;

            if (owner == 2'b01)
                m0_service_beats = m0_service_beats + 1;
            else
                m1_service_beats = m1_service_beats + 1;

            s0_wr_service_valid = 1'b0;
        end

        // Simulate B response delay
        repeat (2)
            @(posedge aclk);

        #1;

         if (owner == 2'b01) begin
            m0_write_done = 1'b1;
            @(negedge aclk);
            m0_write_done = 1'b0;
        end
        else begin
            m1_write_done = 1'b1;
            @(negedge aclk);
            m1_write_done = 1'b0;
        end
    end
endtask


//------------------------------------------------
// ARBITRATION AND WRITE CONTROL
//------------------------------------------------

initial begin

    active_owner = 2'b00;
    active_beats = 0;
    beat_index = 0;

    s0_wr_enable = 1'b0;
    s0_wr_grant_accept = 1'b0;

    s1_wr_enable = 1'b0;
    s1_wr_grant_accept = 1'b0;

    s0_wr_service_valid = 1'b0;
    s0_wr_service_master = 1'b0;

    s1_wr_service_valid = 1'b0;
    s1_wr_service_master = 2'b00;

    wait(aresetn == 1'b1);

    repeat (2)
        @(negedge aclk);

    while ((m0_aw_count < TARGET_TXNS) ||
       (m1_aw_count < TARGET_TXNS)) begin

        s0_wr_enable = 1'b1;

        // Wait until the arbiter selects a master
        wait(s0_wr_grant != 2'b00);

        @(negedge aclk);

               active_owner = s0_wr_grant;

        // Calculate AW waiting time
        if (active_owner == 2'b01) begin
            m0_wait_current = cycle_count - m0_req_start_cycle;

            m0_wait_total = m0_wait_total + m0_wait_current;
            m0_aw_count = m0_aw_count + 1;

            if (m0_wait_current > m0_wait_max)
                m0_wait_max = m0_wait_current;
        end
        else if (active_owner == 2'b10) begin
            m1_wait_current = cycle_count - m1_req_start_cycle;

            m1_wait_total = m1_wait_total + m1_wait_current;
            m1_aw_count = m1_aw_count + 1;

            if (m1_wait_current > m1_wait_max)
                m1_wait_max = m1_wait_current;
        end

        // Accept the AW grant
        s0_wr_grant_accept = 1'b1;

        @(posedge aclk);
        #1;

                s0_wr_grant_accept = 1'b0;
        s0_wr_enable = 1'b0;

        // Notify the selected master
        if (active_owner == 2'b01)
            m0_aw_accepted = 1'b1;
        else
            m1_aw_accepted = 1'b1;

        // Clear acceptance notification after one cycle
        @(negedge aclk);
        m0_aw_accepted = 1'b0;
        m1_aw_accepted = 1'b0;

        // Model the selected master's W burst
        if (active_owner == 2'b01)
            serve_write_burst(active_owner, M0_BURST_BEATS);
        else
            serve_write_burst(active_owner, M1_BURST_BEATS);

        
    end

    s0_wr_enable = 1'b0;

end
    //================================================
    // MASTER 0 REQUEST GENERATOR
    //================================================

    task master0_generator;
        begin

            s0_wr_req[0] = 1'b0;

            repeat (2) @(negedge aclk);

            while (m0_txn_count < TARGET_TXNS) begin

                s0_wr_req[0] = 1'b1;
                m0_req_start_cycle = cycle_count;

                wait(m0_aw_accepted == 1'b1);

                @(negedge aclk);
                s0_wr_req[0] = 1'b0;

                wait(m0_write_done == 1'b1);

                m0_txn_count = m0_txn_count + 1;

                repeat (M0_GAP_CYCLES)
                    @(negedge aclk);

            end

        end
    endtask


    //================================================
    // MASTER 1 REQUEST GENERATOR
    //================================================

    task master1_generator;
        begin

            s0_wr_req[1] = 1'b0;

            repeat (2) @(negedge aclk);

            while (m1_txn_count < TARGET_TXNS) begin

                s0_wr_req[1] = 1'b1;
                m1_req_start_cycle = cycle_count;

                wait(m1_aw_accepted == 1'b1);

                @(negedge aclk);
                s0_wr_req[1] = 1'b0;

                wait(m1_write_done == 1'b1);

                m1_txn_count = m1_txn_count + 1;

                repeat (M1_GAP_CYCLES)
                    @(negedge aclk);

            end

        end
    endtask

   //================================================
// SIMULATION STARTUP
//================================================

initial begin

    initialize_signals();

    // Apply reset
    repeat (5)
        @(negedge aclk);

    aresetn = 1'b1;

    // Start both masters independently
    fork
        master0_generator();
        master1_generator();
    join

    // Allow final activity to settle
    repeat (5)
        @(posedge aclk);

//================================================
// TEST VALIDATION
//================================================

if ((m0_txn_count != TARGET_TXNS) ||
    (m1_txn_count != TARGET_TXNS)) begin
    $display("ERROR: Transaction count mismatch!");
end
else if ((m0_service_beats !=
          TARGET_TXNS * M0_BURST_BEATS) ||
         (m1_service_beats !=
          TARGET_TXNS * M1_BURST_BEATS)) begin
    $display("ERROR: W service beat count mismatch!");
end
else if (contention_cycles == 0) begin
    $display("ERROR: No simultaneous master contention!");
end
else begin
    $display("PASS: Transaction, service and contention checks");
end

    $display("\n============================================");
$display("       WRITE ARBITRATION RESULTS");
$display("============================================");

$display("Policy                  = %b", arb_policy);
$display("M0 Transactions         = %0d", m0_txn_count);
$display("M1 Transactions         = %0d", m1_txn_count);

$display("--------------------------------------------");
$display("M0 Total AW Wait        = %0d", m0_wait_total);
$display("M0 Average AW Wait      = %0f",
         (m0_aw_count != 0) ?
         (1.0 * m0_wait_total / m0_aw_count) : 0.0);
$display("M0 Maximum AW Wait      = %0d", m0_wait_max);
$display("M0 W Service Beats      = %0d", m0_service_beats);

$display("--------------------------------------------");
$display("M1 Total AW Wait        = %0d", m1_wait_total);
$display("M1 Average AW Wait      = %0f",
         (m1_aw_count != 0) ?
         (1.0 * m1_wait_total / m1_aw_count) : 0.0);
$display("M1 Maximum AW Wait      = %0d", m1_wait_max);
$display("M1 W Service Beats      = %0d", m1_service_beats);

$display("--------------------------------------------");
$display("Contention Cycles       = %0d", contention_cycles);
$display("Total Execution Cycles  = %0d", cycle_count);
$display("============================================");

    $finish;

end

//================================================
// WATCHDOG
//================================================

initial begin
    #200000;
    $display("ERROR: Simulation watchdog timeout!");
    $finish;
end

endmodule
