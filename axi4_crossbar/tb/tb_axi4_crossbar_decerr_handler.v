
`timescale 1ns / 1ps

module tb_axi4_crossbar_decerr_handler;

    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH = 4;

    reg aclk;
    reg aresetn;

    // Read address
    reg [ID_WIDTH-1:0] m_arid;
    reg [7:0] m_arlen;
    reg m_arvalid;
    wire m_arready;

    // Read response
    wire [ID_WIDTH-1:0] m_rid;
    wire [DATA_WIDTH-1:0] m_rdata;
    wire [1:0] m_rresp;
    wire m_rlast;
    wire m_rvalid;
    reg m_rready;

    // Write address
    reg [ID_WIDTH-1:0] m_awid;
    reg [7:0] m_awlen;
    reg m_awvalid;
    wire m_awready;

    // Write data
    reg [DATA_WIDTH-1:0] m_wdata;
    reg [DATA_WIDTH/8-1:0] m_wstrb;
    reg m_wlast;
    reg m_wvalid;
    wire m_wready;

    // Write response
    wire [ID_WIDTH-1:0] m_bid;
    wire [1:0] m_bresp;
    wire m_bvalid;
    reg m_bready;

    integer pass_count;
    integer fail_count;
    integer beat_count;

    axi4_crossbar_decerr_handler #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .m_arid(m_arid),
        .m_arlen(m_arlen),
        .m_arvalid(m_arvalid),
        .m_arready(m_arready),

        .m_rid(m_rid),
        .m_rdata(m_rdata),
        .m_rresp(m_rresp),
        .m_rlast(m_rlast),
        .m_rvalid(m_rvalid),
        .m_rready(m_rready),

        .m_awid(m_awid),
        .m_awlen(m_awlen),
        .m_awvalid(m_awvalid),
        .m_awready(m_awready),

        .m_wdata(m_wdata),
        .m_wstrb(m_wstrb),
        .m_wlast(m_wlast),
        .m_wvalid(m_wvalid),
        .m_wready(m_wready),

        .m_bid(m_bid),
        .m_bresp(m_bresp),
        .m_bvalid(m_bvalid),
        .m_bready(m_bready)
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
            @(negedge aclk);
            aresetn = 0;
            #2;
            @(negedge aclk);
            aresetn = 1;
            #1;
        end
    endtask

    // Accept a read address
    task send_ar;
        input [ID_WIDTH-1:0] id;
        input [7:0] length;
        begin
            @(negedge aclk);
            m_arid = id;
            m_arlen = length;
            m_arvalid = 1;

            while (!m_arready)
                @(negedge aclk);

            @(posedge aclk);
            #1;
            m_arvalid = 0;
        end
    endtask

    // Accept a write address
    task send_aw;
        input [ID_WIDTH-1:0] id;
        input [7:0] length;
        begin
            @(negedge aclk);
            m_awid = id;
            m_awlen = length;
            m_awvalid = 1;

            while (!m_awready)
                @(negedge aclk);

            @(posedge aclk);
            #1;
            m_awvalid = 0;
        end
    endtask

    // Send one write data beat
    task send_w;
        input last;
        begin
            @(negedge aclk);
            m_wdata = 32'hA5A50000 + beat_count;
            m_wstrb = 4'b1111;
            m_wlast = last;
            m_wvalid = 1;

            while (!m_wready)
                @(negedge aclk);

            @(posedge aclk);
            #1;
            m_wvalid = 0;
            beat_count = beat_count + 1;
        end
    endtask

    initial begin
        pass_count = 0;
        fail_count = 0;
        beat_count = 0;

        aresetn = 0;

        m_arid = 0;
        m_arlen = 0;
        m_arvalid = 0;
        m_rready = 0;

        m_awid = 0;
        m_awlen = 0;
        m_awvalid = 0;

        m_wdata = 0;
        m_wstrb = 0;
        m_wlast = 0;
        m_wvalid = 0;

        m_bready = 0;

        #12;
        aresetn = 1;
        #2;

        $display("AXI4 CROSSBAR DECERR HANDLER TEST STARTED");

        // --------------------------------------------
        // Test 1: Single-beat read DECERR
        // --------------------------------------------

        send_ar(4'h3, 8'd0);

        #1;
        check(m_rvalid && m_rid == 4'h3 &&
              m_rdata == 32'h00000000 &&
              m_rresp == 2'b11 && m_rlast,
              "Single-beat read DECERR");

        m_rready = 1;
        @(posedge aclk);
        #1;
        m_rready = 0;

        check(!m_rvalid, "Single-beat read completed");

        // --------------------------------------------
        // Test 2: Four-beat read DECERR
        // --------------------------------------------

        send_ar(4'hA, 8'd3);

        beat_count = 0;

        repeat (4) begin
            #1;
            check(m_rvalid && m_rid == 4'hA &&
                  m_rdata == 0 && m_rresp == 2'b11,
                  "Four-beat read DECERR data and ID");

            if (beat_count == 3)
                check(m_rlast, "RLAST asserted on final beat");
            else
                check(!m_rlast, "RLAST low on non-final beat");

            m_rready = 1;
            @(posedge aclk);
            #1;
            m_rready = 0;

            beat_count = beat_count + 1;
        end

        check(!m_rvalid, "Four-beat read completed");

        // --------------------------------------------
        // Test 3: Read backpressure
        // --------------------------------------------

        send_ar(4'h5, 8'd1);

        #1;
        check(m_rvalid && !m_rready,
              "Read response valid during backpressure");

        check(m_rid == 4'h5 && !m_rlast,
              "Read payload remains correct during stall");

        repeat (3) begin
            @(posedge aclk);
            #1;
            check(m_rvalid && m_rid == 4'h5 &&
                  !m_rlast,
                  "Read response held stable during stall");
        end

        m_rready = 1;
        @(posedge aclk);
        #1;
        m_rready = 0;

        check(m_rvalid && m_rlast,
              "Final read beat follows accepted first beat");

        m_rready = 1;
        @(posedge aclk);
        #1;
        m_rready = 0;

        check(!m_rvalid,
              "Read handler releases after final beat");

        // --------------------------------------------
        // Test 4: Single-beat write DECERR
        // --------------------------------------------

        send_aw(4'h7, 8'd0);

        check(m_wready,
              "Write data accepted after AW");

        send_w(1'b1);

        #1;
        check(m_bvalid && m_bid == 4'h7 &&
              m_bresp == 2'b11,
              "Single-beat write DECERR response");

        m_bready = 1;
        @(posedge aclk);
        #1;
        m_bready = 0;

        check(!m_bvalid,
              "Single-beat write response completed");

        // --------------------------------------------
        // Test 5: Four-beat write DECERR
        // --------------------------------------------

        send_aw(4'hC, 8'd3);

        repeat (4) begin
            send_w(beat_count == 0 ? 1'b0 :
                   beat_count == 1 ? 1'b0 :
                   beat_count == 2 ? 1'b0 : 1'b1);
        end

        #1;
        check(m_bvalid && m_bid == 4'hC &&
              m_bresp == 2'b11,
              "Four-beat write DECERR response");

        m_bready = 1;
        @(posedge aclk);
        #1;
        m_bready = 0;

        check(!m_bvalid,
              "Four-beat write response completed");

        // --------------------------------------------
        // Test 6: Write response backpressure
        // --------------------------------------------

        beat_count = 0;
        send_aw(4'h9, 8'd0);
        send_w(1'b1);

        #1;
        check(m_bvalid && !m_bready,
              "B response valid during backpressure");

        repeat (3) begin
            @(posedge aclk);
            #1;
            check(m_bvalid && m_bid == 4'h9 &&
                  m_bresp == 2'b11,
                  "B response held stable during stall");
        end

        m_bready = 1;
        @(posedge aclk);
        #1;
        m_bready = 0;

        check(!m_bvalid,
              "Write handler releases after B handshake");

        // --------------------------------------------
        // Test 7: Independent read and write operation
        // --------------------------------------------

        beat_count = 0;
        send_ar(4'h2, 8'd1);
        send_aw(4'h4, 8'd0);

        #1;
        check(m_rvalid && m_wready,
              "Read and write operations active independently");

        // Finish the read burst
        m_rready = 1;
        @(posedge aclk);
        #1;

        check(m_rvalid && m_rlast,
              "Independent read final beat");

        @(posedge aclk);
        #1;
        m_rready = 0;

        // Finish the write burst
        send_w(1'b1);

        #1;
        check(m_bvalid && m_bid == 4'h4,
              "Independent write response generated");

        m_bready = 1;
        @(posedge aclk);
        #1;
        m_bready = 0;

        check(!m_bvalid,
              "Independent write response completed");

        // --------------------------------------------
        // Final result
        // --------------------------------------------

        $display("----------------------------------");
        $display("TOTAL PASSED: %0d", pass_count);
        $display("TOTAL FAILED: %0d", fail_count);

        if (fail_count == 0)
            $display("ALL DECERR HANDLER TESTS PASSED!");
        else
            $display("DECERR HANDLER TESTS FAILED!");

        $finish;
    end

endmodule
