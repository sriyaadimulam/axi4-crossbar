
`timescale 1ns / 1ps

module tb_axi4_crossbar_b_router;

    parameter ID_WIDTH = 4;

    reg aclk;
    reg aresetn;

    wire [ID_WIDTH-1:0] m0_bid;
    wire [1:0] m0_bresp;
    wire m0_bvalid;
    reg m0_bready;

    wire [ID_WIDTH-1:0] m1_bid;
    wire [1:0] m1_bresp;
    wire m1_bvalid;
    reg m1_bready;

    reg [ID_WIDTH-1:0] s0_bid;
    reg [1:0] s0_bresp;
    reg s0_bvalid;
    wire s0_bready;

    reg [ID_WIDTH-1:0] s1_bid;
    reg [1:0] s1_bresp;
    reg s1_bvalid;
    wire s1_bready;

    reg s0_aw_accept;
    reg s0_aw_owner;
    reg s1_aw_accept;
    reg s1_aw_owner;

    integer pass_count;
    integer fail_count;

    axi4_crossbar_b_router #(
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .m0_bid(m0_bid),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),

        .m1_bid(m1_bid),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),

        .s0_bid(s0_bid),
        .s0_bresp(s0_bresp),
        .s0_bvalid(s0_bvalid),
        .s0_bready(s0_bready),

        .s1_bid(s1_bid),
        .s1_bresp(s1_bresp),
        .s1_bvalid(s1_bvalid),
        .s1_bready(s1_bready),

        .s0_aw_accept(s0_aw_accept),
        .s0_aw_owner(s0_aw_owner),
        .s1_aw_accept(s1_aw_accept),
        .s1_aw_owner(s1_aw_owner)
    );

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

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

    task accept_s0_aw;
        input owner;
        begin
            @(negedge aclk);
            s0_aw_owner = owner;
            s0_aw_accept = 1;
            @(posedge aclk);
            #1;
            s0_aw_accept = 0;
        end
    endtask

    task accept_s1_aw;
        input owner;
        begin
            @(negedge aclk);
            s1_aw_owner = owner;
            s1_aw_accept = 1;
            @(posedge aclk);
            #1;
            s1_aw_accept = 0;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        aresetn = 0;

        m0_bready = 0;
        m1_bready = 0;

        s0_bid = 0;
        s0_bresp = 0;
        s0_bvalid = 0;

        s1_bid = 0;
        s1_bresp = 0;
        s1_bvalid = 0;

        s0_aw_accept = 0;
        s0_aw_owner = 0;
        s1_aw_accept = 0;
        s1_aw_owner = 0;

        #12;
        aresetn = 1;
        #2;

        $display("AXI4 CROSSBAR B ROUTER TEST STARTED");

        // Test 1: S0 response routed to M0
        accept_s0_aw(1'b0);

        s0_bid = 4'h3;
        s0_bresp = 2'b00;
        s0_bvalid = 1;
        #1;

        check(m0_bvalid && !m1_bvalid &&
              m0_bid == 4'h3 && m0_bresp == 2'b00,
              "S0 response routed to M0");

        check(!s0_bready,
              "S0 BREADY remains low during backpressure");

        m0_bready = 1;
        #1;

        check(s0_bready && !s1_bready,
              "M0 BREADY returned to S0");

        // Complete response
        @(posedge aclk);
        #1;
        s0_bvalid = 0;
        m0_bready = 0;

        check(!m0_bvalid,
              "S0 response ownership released");

        // Test 2: S0 response routed to M1
        accept_s0_aw(1'b1);

        s0_bid = 4'hA;
        s0_bresp = 2'b10;
        s0_bvalid = 1;
        #1;

        check(m1_bvalid && !m0_bvalid &&
              m1_bid == 4'hA && m1_bresp == 2'b10,
              "S0 response routed to M1");

        m1_bready = 1;
        #1;

        check(s0_bready && !s1_bready,
              "M1 BREADY returned to S0");

        @(posedge aclk);
        #1;
        s0_bvalid = 0;
        m1_bready = 0;

        // Test 3: S1 response routed to M0
        accept_s1_aw(1'b0);

        s1_bid = 4'h5;
        s1_bresp = 2'b01;
        s1_bvalid = 1;
        #1;

        check(m0_bvalid && !m1_bvalid &&
              m0_bid == 4'h5 && m0_bresp == 2'b01,
              "S1 response routed to M0");

        m0_bready = 1;
        #1;

        check(s1_bready && !s0_bready,
              "M0 BREADY returned to S1");

        @(posedge aclk);
        #1;
        s1_bvalid = 0;
        m0_bready = 0;

        // Test 4: S1 response routed to M1
        accept_s1_aw(1'b1);

        s1_bid = 4'hC;
        s1_bresp = 2'b00;
        s1_bvalid = 1;
        #1;

        check(m1_bvalid && !m0_bvalid &&
              m1_bid == 4'hC && m1_bresp == 2'b00,
              "S1 response routed to M1");

        m1_bready = 1;
        #1;

        check(s1_bready && !s0_bready,
              "M1 BREADY returned to S1");

        @(posedge aclk);
        #1;
        s1_bvalid = 0;
        m1_bready = 0;

        // Test 5: Simultaneous responses to different masters
        accept_s0_aw(1'b0);
        accept_s1_aw(1'b1);

        s0_bid = 4'h1;
        s0_bresp = 2'b00;
        s0_bvalid = 1;

        s1_bid = 4'h2;
        s1_bresp = 2'b10;
        s1_bvalid = 1;

        #1;

        check(m0_bvalid && m1_bvalid &&
              m0_bid == 4'h1 && m1_bid == 4'h2,
              "Simultaneous responses routed independently");

        m0_bready = 1;
        m1_bready = 1;
        #1;

        check(s0_bready && s1_bready,
              "Independent BREADY for both slaves");

        @(posedge aclk);
        #1;

        s0_bvalid = 0;
        s1_bvalid = 0;
        m0_bready = 0;
        m1_bready = 0;

        // Test 6: Response backpressure
        accept_s0_aw(1'b0);

        s0_bid = 4'h7;
        s0_bresp = 2'b11;
        s0_bvalid = 1;
        m0_bready = 0;
        #1;

        check(m0_bvalid && !s0_bready &&
              m0_bid == 4'h7 && m0_bresp == 2'b11,
              "B response payload held under backpressure");

        m0_bready = 1;
        #1;

        check(s0_bready,
              "S0 accepts response when M0 is ready");

        @(posedge aclk);
        #1;

        s0_bvalid = 0;
        m0_bready = 0;

        check(!m0_bvalid,
              "Ownership released after B handshake");

        // Test 7: No response without AW ownership
        s0_bvalid = 1;
        s1_bvalid = 1;
        #1;

        check(!m0_bvalid && !m1_bvalid &&
              !s0_bready && !s1_bready,
              "Responses blocked without accepted AW");

        $display("----------------------------------");
        $display("TOTAL PASSED: %0d", pass_count);
        $display("TOTAL FAILED: %0d", fail_count);

        if (fail_count == 0)
            $display("ALL B ROUTER TESTS PASSED!");
        else
            $display("B ROUTER TESTS FAILED!");

        $finish;
    end

endmodule
