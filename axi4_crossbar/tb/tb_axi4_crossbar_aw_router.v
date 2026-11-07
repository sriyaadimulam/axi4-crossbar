
`timescale 1ns / 1ps

module tb_axi4_crossbar_aw_router;

    reg aclk, aresetn;

    // Master 0
    reg [3:0] m0_awid;
    reg [31:0] m0_awaddr;
    reg [7:0] m0_awlen;
    reg [2:0] m0_awsize;
    reg [1:0] m0_awburst;
    reg m0_awlock;
    reg [3:0] m0_awcache;
    reg [2:0] m0_awprot;
    reg [3:0] m0_awqos, m0_awregion;
    reg m0_awvalid;
    wire m0_awready;

    // Master 1
    reg [3:0] m1_awid;
    reg [31:0] m1_awaddr;
    reg [7:0] m1_awlen;
    reg [2:0] m1_awsize;
    reg [1:0] m1_awburst;
    reg m1_awlock;
    reg [3:0] m1_awcache;
    reg [2:0] m1_awprot;
    reg [3:0] m1_awqos, m1_awregion;
    reg m1_awvalid;
    wire m1_awready;

    // Slave 0
    wire [3:0] s0_awid;
    wire [31:0] s0_awaddr;
    wire [7:0] s0_awlen;
    wire [2:0] s0_awsize;
    wire [1:0] s0_awburst;
    wire s0_awlock;
    wire [3:0] s0_awcache;
    wire [2:0] s0_awprot;
    wire [3:0] s0_awqos, s0_awregion;
    wire s0_awvalid;
    reg s0_awready;

    // Slave 1
    wire [3:0] s1_awid;
    wire [31:0] s1_awaddr;
    wire [7:0] s1_awlen;
    wire [2:0] s1_awsize;
    wire [1:0] s1_awburst;
    wire s1_awlock;
    wire [3:0] s1_awcache;
    wire [2:0] s1_awprot;
    wire [3:0] s1_awqos, s1_awregion;
    wire s1_awvalid;
    reg s1_awready;

    // Arbitration connections
    reg m0_write_available, m1_write_available;

    wire [1:0] s0_wr_req, s1_wr_req;
    reg [1:0] s0_wr_grant, s1_wr_grant;
    reg s0_wr_enable, s1_wr_enable;

    wire s0_wr_grant_accept, s1_wr_grant_accept;
    wire s0_aw_owner, s1_aw_owner;
    wire m0_aw_unmapped, m1_aw_unmapped;

    integer errors;

    axi4_crossbar_aw_router DUT (
        .aclk(aclk),
        .aresetn(aresetn),

        .m0_awid(m0_awid),
        .m0_awaddr(m0_awaddr),
        .m0_awlen(m0_awlen),
        .m0_awsize(m0_awsize),
        .m0_awburst(m0_awburst),
        .m0_awlock(m0_awlock),
        .m0_awcache(m0_awcache),
        .m0_awprot(m0_awprot),
        .m0_awqos(m0_awqos),
        .m0_awregion(m0_awregion),
        .m0_awvalid(m0_awvalid),
        .m0_awready(m0_awready),

        .m1_awid(m1_awid),
        .m1_awaddr(m1_awaddr),
        .m1_awlen(m1_awlen),
        .m1_awsize(m1_awsize),
        .m1_awburst(m1_awburst),
        .m1_awlock(m1_awlock),
        .m1_awcache(m1_awcache),
        .m1_awprot(m1_awprot),
        .m1_awqos(m1_awqos),
        .m1_awregion(m1_awregion),
        .m1_awvalid(m1_awvalid),
        .m1_awready(m1_awready),

        .s0_awid(s0_awid),
        .s0_awaddr(s0_awaddr),
        .s0_awlen(s0_awlen),
        .s0_awsize(s0_awsize),
        .s0_awburst(s0_awburst),
        .s0_awlock(s0_awlock),
        .s0_awcache(s0_awcache),
        .s0_awprot(s0_awprot),
        .s0_awqos(s0_awqos),
        .s0_awregion(s0_awregion),
        .s0_awvalid(s0_awvalid),
        .s0_awready(s0_awready),

        .s1_awid(s1_awid),
        .s1_awaddr(s1_awaddr),
        .s1_awlen(s1_awlen),
        .s1_awsize(s1_awsize),
        .s1_awburst(s1_awburst),
        .s1_awlock(s1_awlock),
        .s1_awcache(s1_awcache),
        .s1_awprot(s1_awprot),
        .s1_awqos(s1_awqos),
        .s1_awregion(s1_awregion),
        .s1_awvalid(s1_awvalid),
        .s1_awready(s1_awready),

        .m0_write_available(m0_write_available),
        .m1_write_available(m1_write_available),

        .s0_wr_req(s0_wr_req),
        .s0_wr_grant(s0_wr_grant),
        .s0_wr_enable(s0_wr_enable),

        .s1_wr_req(s1_wr_req),
        .s1_wr_grant(s1_wr_grant),
        .s1_wr_enable(s1_wr_enable),

        .s0_wr_grant_accept(s0_wr_grant_accept),
        .s1_wr_grant_accept(s1_wr_grant_accept),

        .s0_aw_owner(s0_aw_owner),
        .s1_aw_owner(s1_aw_owner),

        .m0_aw_unmapped(m0_aw_unmapped),
        .m1_aw_unmapped(m1_aw_unmapped)
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

    task clear_masters;
        begin
            m0_awvalid = 0;
            m1_awvalid = 0;
            m0_awaddr = 0;
            m1_awaddr = 0;
            m0_write_available = 1;
            m1_write_available = 1;
        end
    endtask

    initial begin

        errors = 0;
        aresetn = 0;

        m0_awid = 4'h1;
        m0_awaddr = 0;
        m0_awlen = 8'd3;
        m0_awsize = 3'd2;
        m0_awburst = 2'b01;
        m0_awlock = 0;
        m0_awcache = 0;
        m0_awprot = 0;
        m0_awqos = 0;
        m0_awregion = 0;
        m0_awvalid = 0;

        m1_awid = 4'h2;
        m1_awaddr = 0;
        m1_awlen = 8'd7;
        m1_awsize = 3'd2;
        m1_awburst = 2'b01;
        m1_awlock = 0;
        m1_awcache = 0;
        m1_awprot = 0;
        m1_awqos = 0;
        m1_awregion = 0;
        m1_awvalid = 0;

        s0_awready = 0;
        s1_awready = 0;

        s0_wr_grant = 0;
        s1_wr_grant = 0;
        s0_wr_enable = 1;
        s1_wr_enable = 1;

        clear_masters();

        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        $display("\nAXI4 CROSSBAR AW ROUTER TEST STARTED\n");

        // TEST 1: M0 to S0
        m0_awvalid = 1;
        m0_awaddr = 32'h00001234;
        s0_wr_grant = 2'b01;
        s0_awready = 1;

        #1;
        check(s0_wr_req == 2'b01 &&
              s0_awvalid &&
              s0_awaddr == 32'h00001234 &&
              s0_awid == 4'h1 &&
              m0_awready && !m1_awready,
              "M0 routed to S0");

        // TEST 2: M0 to S1
        clear_masters();
        s0_wr_grant = 0;

        m0_awvalid = 1;
        m0_awaddr = 32'h00010020;
        s1_wr_grant = 2'b01;
        s1_awready = 1;

        #1;
        check(s1_wr_req == 2'b01 &&
              s1_awvalid &&
              s1_awaddr == 32'h00010020 &&
              m0_awready && !m1_awready,
              "M0 routed to S1");

        // TEST 3: M1 to S0
        clear_masters();
        s1_wr_grant = 0;

        m1_awvalid = 1;
        m1_awaddr = 32'h0000ABCD;
        s0_wr_grant = 2'b10;
        s0_awready = 1;

        #1;
        check(s0_wr_req == 2'b10 &&
              s0_awvalid &&
              s0_awaddr == 32'h0000ABCD &&
              s0_awid == 4'h2 &&
              m1_awready && !m0_awready,
              "M1 routed to S0");

        // TEST 4: M1 to S1
        clear_masters();
        s0_wr_grant = 0;

        m1_awvalid = 1;
        m1_awaddr = 32'h0001ABCD;
        s1_wr_grant = 2'b10;
        s1_awready = 1;

        #1;
        check(s1_wr_req == 2'b10 &&
              s1_awvalid &&
              s1_awaddr == 32'h0001ABCD &&
              s1_awid == 4'h2 &&
              m1_awready && !m0_awready,
              "M1 routed to S1");

        // TEST 5: Simultaneous writes to different slaves
        clear_masters();

        m0_awvalid = 1;
        m0_awaddr = 32'h00000080;

        m1_awvalid = 1;
        m1_awaddr = 32'h00010080;

        s0_wr_grant = 2'b01;
        s1_wr_grant = 2'b10;
        s0_awready = 1;
        s1_awready = 1;

        #1;
        check(s0_awvalid && s1_awvalid &&
              m0_awready && m1_awready &&
              s0_awaddr == 32'h00000080 &&
              s1_awaddr == 32'h00010080,
              "Simultaneous M0-to-S0 and M1-to-S1");

        // TEST 6: Same-slave contention, M0 wins
        clear_masters();

        m0_awvalid = 1;
        m0_awaddr = 32'h00000040;

        m1_awvalid = 1;
        m1_awaddr = 32'h00000060;

        s0_wr_grant = 2'b01;
        s1_wr_grant = 0;
        s0_awready = 1;

        #1;
        check(s0_wr_req == 2'b11 &&
              s0_awvalid &&
              s0_awaddr == 32'h00000040 &&
              m0_awready && !m1_awready,
              "S0 contention: M0 grant selected");

        // TEST 7: Backpressure
        s0_awready = 0;

        #1;
        check(s0_awvalid &&
              s0_awaddr == 32'h00000040 &&
              !m0_awready,
              "S0 backpressure holds AWVALID and payload");

        // TEST 8: Unmapped address
        clear_masters();
        s0_wr_grant = 0;

        m0_awvalid = 1;
        m0_awaddr = 32'h00020000;

        #1;
        check(m0_aw_unmapped &&
              s0_wr_req == 2'b00 &&
              s1_wr_req == 2'b00 &&
              !s0_awvalid && !s1_awvalid,
              "Unmapped write address detected");

        // TEST 9: Master unavailable
        clear_masters();

        m0_write_available = 0;
        m0_awvalid = 1;
        m0_awaddr = 32'h00000020;
        s0_wr_grant = 2'b01;

        #1;
        check(s0_wr_req == 2'b00 &&
              !s0_awvalid && !m0_awready,
              "Unavailable master is blocked");

        // TEST 10: Handshake and owner encoding
        clear_masters();

        m1_awvalid = 1;
        m1_awaddr = 32'h00000020;
        s0_wr_grant = 2'b10;
        s0_awready = 1;

        #1;
        check(s0_wr_grant_accept &&
              s0_aw_owner == 1'b1,
              "S0 handshake identifies M1 owner");

        // TEST 11: M0 owner encoding
        s0_wr_grant = 2'b01;

        #1;
        check(s0_aw_owner == 1'b0,
              "S0 grant identifies M0 owner");

        // RESULTS
        if (errors == 0)
            $display("\nALL AW ROUTER TESTS PASSED!");
        else
            $display("\nAW ROUTER TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule
