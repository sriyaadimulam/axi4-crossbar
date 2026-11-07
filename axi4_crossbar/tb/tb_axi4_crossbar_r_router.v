
`timescale 1ns / 1ps

module tb_axi4_crossbar_r_router;

    reg aclk, aresetn;

    // Accepted AR transactions
    reg s0_ar_accept, s0_ar_owner;
    reg s1_ar_accept, s1_ar_owner;

    // Slave 0 R interface
    reg [3:0] s0_rid;
    reg [31:0] s0_rdata;
    reg [1:0] s0_rresp;
    reg s0_rlast, s0_rvalid;
    wire s0_rready;

    // Slave 1 R interface
    reg [3:0] s1_rid;
    reg [31:0] s1_rdata;
    reg [1:0] s1_rresp;
    reg s1_rlast, s1_rvalid;
    wire s1_rready;

    // Master 0 R interface
    wire [3:0] m0_rid;
    wire [31:0] m0_rdata;
    wire [1:0] m0_rresp;
    wire m0_rlast, m0_rvalid;
    reg m0_rready;

    // Master 1 R interface
    wire [3:0] m1_rid;
    wire [31:0] m1_rdata;
    wire [1:0] m1_rresp;
    wire m1_rlast, m1_rvalid;
    reg m1_rready;

    // Ownership status
    wire s0_owner_valid, s1_owner_valid;
    wire s0_owner, s1_owner;

    integer errors;

    axi4_crossbar_r_router DUT (
        .aclk(aclk),
        .aresetn(aresetn),

        .s0_ar_accept(s0_ar_accept),
        .s0_ar_owner(s0_ar_owner),
        .s1_ar_accept(s1_ar_accept),
        .s1_ar_owner(s1_ar_owner),

        .s0_rid(s0_rid),
        .s0_rdata(s0_rdata),
        .s0_rresp(s0_rresp),
        .s0_rlast(s0_rlast),
        .s0_rvalid(s0_rvalid),
        .s0_rready(s0_rready),

        .s1_rid(s1_rid),
        .s1_rdata(s1_rdata),
        .s1_rresp(s1_rresp),
        .s1_rlast(s1_rlast),
        .s1_rvalid(s1_rvalid),
        .s1_rready(s1_rready),

        .m0_rid(m0_rid),
        .m0_rdata(m0_rdata),
        .m0_rresp(m0_rresp),
        .m0_rlast(m0_rlast),
        .m0_rvalid(m0_rvalid),
        .m0_rready(m0_rready),

        .m1_rid(m1_rid),
        .m1_rdata(m1_rdata),
        .m1_rresp(m1_rresp),
        .m1_rlast(m1_rlast),
        .m1_rvalid(m1_rvalid),
        .m1_rready(m1_rready),

        .s0_owner_valid(s0_owner_valid),
        .s1_owner_valid(s1_owner_valid),
        .s0_owner(s0_owner),
        .s1_owner(s1_owner)
    );

    // 100 MHz clock
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end
    

    task check;
    input condition;
    input [255:0] test_name;
    begin
        if (condition) begin
            $display("PASS: %s", test_name);
        end
        else begin
            $display("FAIL: %s", test_name);
            errors = errors + 1;
        end
    end
endtask

    // Capture ownership on the next rising clock edge
    task capture_s0;
        input owner;
        begin
            @(negedge aclk);
            s0_ar_owner = owner;
            s0_ar_accept = 1;

            @(negedge aclk);
            s0_ar_accept = 0;
        end
    endtask

    task capture_s1;
        input owner;
        begin
            @(negedge aclk);
            s1_ar_owner = owner;
            s1_ar_accept = 1;

            @(negedge aclk);
            s1_ar_accept = 0;
        end
    endtask

    initial begin

        errors = 0;
         aclk = 0;

        aresetn = 0;

        s0_ar_accept = 0;
        s0_ar_owner = 0;
        s1_ar_accept = 0;
        s1_ar_owner = 0;

        s0_rid = 0;
        s0_rdata = 0;
        s0_rresp = 0;
        s0_rlast = 0;
        s0_rvalid = 0;

        s1_rid = 0;
        s1_rdata = 0;
        s1_rresp = 0;
        s1_rlast = 0;
        s1_rvalid = 0;

        m0_rready = 0;
        m1_rready = 0;

        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        $display("\nAXI4 CROSSBAR R ROUTER TEST STARTED\n");

        // --------------------------------
        // TEST 1: Reset ownership
        // --------------------------------

        check(!s0_owner_valid && !s1_owner_valid,
              "Reset clears both ownership registers");

        // --------------------------------
        // TEST 2: Capture M0 as S0 owner
        // --------------------------------

        capture_s0(1'b0);
        #1;

        check(s0_owner_valid && !s0_owner,
              "S0 captures M0 ownership");

        // --------------------------------
        // TEST 3: Route S0 response to M0
        // --------------------------------

        s0_rid = 4'h3;
        s0_rdata = 32'h12345678;
        s0_rresp = 2'b00;
        s0_rlast = 1;
        s0_rvalid = 1;
        m0_rready = 1;
        #1;

        check(m0_rvalid &&
              m0_rid == 4'h3 &&
              m0_rdata == 32'h12345678 &&
              m0_rresp == 2'b00 &&
              m0_rlast &&
              s0_rready &&
              !m1_rvalid,
              "S0 response routed to M0");

        // Accept final beat
        @(negedge aclk);
        s0_rvalid = 0;
        @(negedge aclk);
        #1;

        check(!s0_owner_valid,
              "S0 ownership released after accepted RLAST");

        // --------------------------------
        // TEST 4: Capture M1 as S1 owner
        // --------------------------------

        capture_s1(1'b1);
        #1;

        check(s1_owner_valid && s1_owner,
              "S1 captures M1 ownership");

        // --------------------------------
        // TEST 5: Route S1 response to M1
        // --------------------------------

        s1_rid = 4'hA;
        s1_rdata = 32'hABCDEF12;
        s1_rresp = 2'b10;
        s1_rlast = 1;
        s1_rvalid = 1;
        m1_rready = 1;
        #1;

        check(m1_rvalid &&
              m1_rid == 4'hA &&
              m1_rdata == 32'hABCDEF12 &&
              m1_rresp == 2'b10 &&
              m1_rlast &&
              s1_rready &&
              !m0_rvalid,
              "S1 response routed to M1");

        @(negedge aclk);
        s1_rvalid = 0;
        @(negedge aclk);
        #1;

        check(!s1_owner_valid,
              "S1 ownership released after accepted RLAST");

        // --------------------------------
        // TEST 6: Backpressure
        // --------------------------------

        capture_s0(1'b0);

        s0_rid = 4'h5;
        s0_rdata = 32'hDEADBEEF;
        s0_rresp = 2'b00;
        s0_rlast = 1;
        s0_rvalid = 1;
        m0_rready = 0;
        #1;

        check(m0_rvalid &&
              !s0_rready &&
              s0_owner_valid,
              "M0 backpressure blocks S0 response");

        // Ownership must remain while stalled
        @(negedge aclk);
        check(s0_owner_valid,
              "Ownership retained during backpressure");

        // Release backpressure
        m0_rready = 1;
        #1;

        check(s0_rready,
              "S0 response accepted after READY");

        @(negedge aclk);
        s0_rvalid = 0;
        @(negedge aclk);
        #1;

        check(!s0_owner_valid,
              "Ownership released after stalled final beat");

        // --------------------------------
        // TEST 7: Multi-beat response
        // --------------------------------

        capture_s1(1'b0);

        m0_rready = 1;

        s1_rid = 4'h7;
        s1_rdata = 32'h11111111;
        s1_rresp = 2'b00;
        s1_rlast = 0;
        s1_rvalid = 1;
        #1;

        check(m0_rvalid && !m0_rlast,
              "First non-final read beat routed");

        @(negedge aclk);
        s1_rdata = 32'h22222222;
        s1_rlast = 0;
        #1;

        check(m0_rvalid && !m0_rlast &&
              m0_rdata == 32'h22222222,
              "Second non-final read beat routed");

        @(negedge aclk);
        s1_rdata = 32'h33333333;
        s1_rlast = 1;
        #1;

        check(m0_rvalid && m0_rlast,
              "Final read beat routed");

        @(negedge aclk);
        s1_rvalid = 0;
        @(negedge aclk);
        #1;

        check(!s1_owner_valid,
              "Multi-beat ownership released after final beat");

        // --------------------------------
        // TEST 8: Simultaneous responses
        // Different masters, different slaves
        // --------------------------------

        capture_s0(1'b0);
        capture_s1(1'b1);

        s0_rid = 4'h1;
        s0_rdata = 32'hAAAA0001;
        s0_rresp = 2'b00;
        s0_rlast = 1;
        s0_rvalid = 1;

        s1_rid = 4'h2;
        s1_rdata = 32'hBBBB0002;
        s1_rresp = 2'b00;
        s1_rlast = 1;
        s1_rvalid = 1;

        m0_rready = 1;
        m1_rready = 1;
        #1;

        check(m0_rvalid && m1_rvalid &&
              m0_rdata == 32'hAAAA0001 &&
              m1_rdata == 32'hBBBB0002 &&
              s0_rready && s1_rready,
              "Simultaneous responses to different masters");

        @(negedge aclk);
        s0_rvalid = 0;
        s1_rvalid = 0;

        @(negedge aclk);
        #1;

        check(!s0_owner_valid && !s1_owner_valid,
              "Both ownership records released");

        // --------------------------------
        // RESULTS
        // --------------------------------

        if (errors == 0)
            $display("\nALL R ROUTER TESTS PASSED!");
        else
            $display("\nR ROUTER TEST FAILED: %0d errors", errors);

        $finish;

    end

endmodule
