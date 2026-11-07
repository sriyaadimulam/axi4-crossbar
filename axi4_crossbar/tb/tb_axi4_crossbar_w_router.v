
`timescale 1ns / 1ps

module tb_axi4_crossbar_w_router;

    parameter DATA_WIDTH = 32;

    reg aclk;
    reg aresetn;

    reg [DATA_WIDTH-1:0] m0_wdata;
    reg [3:0] m0_wstrb;
    reg m0_wlast;
    reg m0_wvalid;
    wire m0_wready;

    reg [DATA_WIDTH-1:0] m1_wdata;
    reg [3:0] m1_wstrb;
    reg m1_wlast;
    reg m1_wvalid;
    wire m1_wready;

    wire [DATA_WIDTH-1:0] s0_wdata;
    wire [3:0] s0_wstrb;
    wire s0_wlast;
    wire s0_wvalid;
    reg s0_wready;

    wire [DATA_WIDTH-1:0] s1_wdata;
    wire [3:0] s1_wstrb;
    wire s1_wlast;
    wire s1_wvalid;
    reg s1_wready;

    reg s0_aw_accept;
    reg s0_aw_owner;
    reg s1_aw_accept;
    reg s1_aw_owner;

    integer pass_count;
    integer fail_count;

    axi4_crossbar_w_router #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .m0_wdata(m0_wdata),
        .m0_wstrb(m0_wstrb),
        .m0_wlast(m0_wlast),
        .m0_wvalid(m0_wvalid),
        .m0_wready(m0_wready),

        .m1_wdata(m1_wdata),
        .m1_wstrb(m1_wstrb),
        .m1_wlast(m1_wlast),
        .m1_wvalid(m1_wvalid),
        .m1_wready(m1_wready),

        .s0_wdata(s0_wdata),
        .s0_wstrb(s0_wstrb),
        .s0_wlast(s0_wlast),
        .s0_wvalid(s0_wvalid),
        .s0_wready(s0_wready),

        .s1_wdata(s1_wdata),
        .s1_wstrb(s1_wstrb),
        .s1_wlast(s1_wlast),
        .s1_wvalid(s1_wvalid),
        .s1_wready(s1_wready),

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

    task reset_dut;
        begin
            aresetn = 0;
            s0_aw_accept = 0;
            s1_aw_accept = 0;
            #12;
            aresetn = 1;
            #2;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;

        m0_wdata = 0;
        m0_wstrb = 0;
        m0_wlast = 0;
        m0_wvalid = 0;

        m1_wdata = 0;
        m1_wstrb = 0;
        m1_wlast = 0;
        m1_wvalid = 0;

        s0_wready = 0;
        s1_wready = 0;

        s0_aw_accept = 0;
        s0_aw_owner = 0;
        s1_aw_accept = 0;
        s1_aw_owner = 0;

        reset_dut();

        $display("AXI4 CROSSBAR W ROUTER TEST STARTED");

        // Test 1: M0 owns Slave 0
        s0_aw_owner = 0;
        s0_aw_accept = 1;
        @(posedge aclk);
        #1;
        s0_aw_accept = 0;

        m0_wvalid = 1;
        m0_wdata = 32'hAABBCCDD;
        m0_wstrb = 4'b1111;
        m0_wlast = 0;
        #1;

        check(s0_wvalid && s0_wdata == 32'hAABBCCDD &&
              s0_wstrb == 4'b1111 && !s1_wvalid,
              "M0 data routed to S0");

        check(!m0_wready && !m1_wready,
      "S0 READY remains low during backpressure");

s0_wready = 1;
#1;

check(m0_wready && !m1_wready,
      "S0 READY returned to M0");

        // Complete S0 transaction
        s0_wready = 1;
        m0_wlast = 1;
        #1;
        check(s0_wvalid && s0_wlast,
              "S0 final W beat routed correctly");

        @(posedge aclk);
        #1;
        m0_wvalid = 0;
        m0_wlast = 0;
        s0_wready = 0;

        check(!s0_wvalid,
              "S0 ownership released after WLAST");

        // Test 2: M1 owns Slave 0
        s0_aw_owner = 1;
        s0_aw_accept = 1;
        @(posedge aclk);
        #1;
        s0_aw_accept = 0;

        m1_wvalid = 1;
        m1_wdata = 32'h12345678;
        m1_wstrb = 4'b0101;
        #1;

        check(s0_wvalid && s0_wdata == 32'h12345678 &&
              s0_wstrb == 4'b0101,
              "M1 data routed to S0");

        check(!m0_wready && !m1_wready,
      "S0 READY remains low during backpressure");

s0_wready = 1;
#1;

check(m1_wready && !m0_wready,
      "S0 READY returned to M1");

        // Complete S0 transaction
        s0_wready = 1;
        m1_wlast = 1;
        #1;
        @(posedge aclk);
        #1;
        m1_wvalid = 0;
        m1_wlast = 0;
        s0_wready = 0;

        // Test 3: M0 owns Slave 1
        s1_aw_owner = 0;
        s1_aw_accept = 1;
        @(posedge aclk);
        #1;
        s1_aw_accept = 0;

        m0_wvalid = 1;
        m0_wdata = 32'hDEADBEEF;
        m0_wstrb = 4'b1010;
        #1;

        check(s1_wvalid && s1_wdata == 32'hDEADBEEF &&
              s1_wstrb == 4'b1010 && !s0_wvalid,
              "M0 data routed to S1");

        check(!m0_wready && !m1_wready,
      "S1 READY remains low during backpressure");

s1_wready = 1;
#1;

check(m0_wready && !m1_wready,
      "S1 READY returned to M0");

        // Complete S1 transaction
        s1_wready = 1;
        m0_wlast = 1;
        #1;
        @(posedge aclk);
        #1;
        m0_wvalid = 0;
        m0_wlast = 0;
        s1_wready = 0;

        // Test 4: M1 owns Slave 1
        s1_aw_owner = 1;
        s1_aw_accept = 1;
        @(posedge aclk);
        #1;
        s1_aw_accept = 0;

        m1_wvalid = 1;
        m1_wdata = 32'hCAFEBABE;
        m1_wstrb = 4'b0011;
        #1;

        check(s1_wvalid && s1_wdata == 32'hCAFEBABE &&
              s1_wstrb == 4'b0011,
              "M1 data routed to S1");

        // Complete S1 transaction
        s1_wready = 1;
        m1_wlast = 1;
        #1;
        @(posedge aclk);
        #1;
        m1_wvalid = 0;
        m1_wlast = 0;
        s1_wready = 0;

        // Test 5: Independent simultaneous transactions
        s0_aw_owner = 0;
        s1_aw_owner = 1;
        s0_aw_accept = 1;
        s1_aw_accept = 1;

        @(posedge aclk);
        #1;
        s0_aw_accept = 0;
        s1_aw_accept = 0;

        m0_wvalid = 1;
        m0_wdata = 32'h11112222;
        m0_wstrb = 4'b1111;

        m1_wvalid = 1;
        m1_wdata = 32'h33334444;
        m1_wstrb = 4'b1100;

        #1;

        check(s0_wvalid && s0_wdata == 32'h11112222 &&
              s1_wvalid && s1_wdata == 32'h33334444,
              "Independent simultaneous S0 and S1 routing");

        check(!m0_wready && !m1_wready,
      "Both READY signals remain low during backpressure");

s0_wready = 1;
s1_wready = 1;
#1;

check(m0_wready && m1_wready,
      "Both masters receive independent READY");
        // Complete both transactions
        s0_wready = 1;
        s1_wready = 1;
        m0_wlast = 1;
        m1_wlast = 1;

        #1;
        @(posedge aclk);
        #1;

        m0_wvalid = 0;
        m1_wvalid = 0;
        m0_wlast = 0;
        m1_wlast = 0;
        s0_wready = 0;
        s1_wready = 0;

        // Test 6: Backpressure
        s0_aw_owner = 0;
        s0_aw_accept = 1;
        @(posedge aclk);
        #1;
        s0_aw_accept = 0;

        m0_wvalid = 1;
        m0_wdata = 32'hFACE1234;
        m0_wstrb = 4'b1111;
        m0_wlast = 0;
        s0_wready = 0;
        #1;

        check(s0_wvalid && !m0_wready &&
              s0_wdata == 32'hFACE1234,
              "S0 backpressure holds WVALID and payload");

        // Release backpressure
        s0_wready = 1;
        #1;
        check(m0_wready,
              "M0 READY asserted when S0 is ready");

        // Complete transaction
        m0_wlast = 1;
        #1;
        @(posedge aclk);
        #1;

        m0_wvalid = 0;
        m0_wlast = 0;
        s0_wready = 0;

        check(!s0_wvalid,
              "Ownership released after final accepted beat");

        // Test 7: No owner means no WVALID
        m0_wvalid = 1;
        m1_wvalid = 1;
        #1;

        check(!s0_wvalid && !s1_wvalid &&
              !m0_wready && !m1_wready,
              "No W transfer without accepted AW");

        $display("----------------------------------");
        $display("TOTAL PASSED: %0d", pass_count);
        $display("TOTAL FAILED: %0d", fail_count);

        if (fail_count == 0)
            $display("ALL W ROUTER TESTS PASSED!");
        else
            $display("W ROUTER TESTS FAILED!");

        $finish;
    end

endmodule
