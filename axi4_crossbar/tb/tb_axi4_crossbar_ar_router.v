
`timescale 1ns / 1ps

module tb_axi4_crossbar_ar_router;

    reg aclk, aresetn;

    // Master 0
    reg [3:0] m0_arid;
    reg [31:0] m0_araddr;
    reg [7:0] m0_arlen;
    reg [2:0] m0_arsize;
    reg [1:0] m0_arburst;
    reg m0_arlock;
    reg [3:0] m0_arcache;
    reg [2:0] m0_arprot;
    reg [3:0] m0_arqos, m0_arregion;
    reg m0_arvalid;
    wire m0_arready;

    // Master 1
    reg [3:0] m1_arid;
    reg [31:0] m1_araddr;
    reg [7:0] m1_arlen;
    reg [2:0] m1_arsize;
    reg [1:0] m1_arburst;
    reg m1_arlock;
    reg [3:0] m1_arcache;
    reg [2:0] m1_arprot;
    reg [3:0] m1_arqos, m1_arregion;
    reg m1_arvalid;
    wire m1_arready;

    // Slave 0
    wire [3:0] s0_arid;
    wire [31:0] s0_araddr;
    wire [7:0] s0_arlen;
    wire [2:0] s0_arsize;
    wire [1:0] s0_arburst;
    wire s0_arlock;
    wire [3:0] s0_arcache;
    wire [2:0] s0_arprot;
    wire [3:0] s0_arqos, s0_arregion;
    wire s0_arvalid;
    reg s0_arready;

    // Slave 1
    wire [3:0] s1_arid;
    wire [31:0] s1_araddr;
    wire [7:0] s1_arlen;
    wire [2:0] s1_arsize;
    wire [1:0] s1_arburst;
    wire s1_arlock;
    wire [3:0] s1_arcache;
    wire [2:0] s1_arprot;
    wire [3:0] s1_arqos, s1_arregion;
    wire s1_arvalid;
    reg s1_arready;

    // Arbitration connections
    reg m0_read_available, m1_read_available;

    wire [1:0] s0_rd_req, s1_rd_req;
    reg [1:0] s0_rd_grant, s1_rd_grant;
    reg s0_rd_enable, s1_rd_enable;

    wire s0_rd_grant_accept, s1_rd_grant_accept;
    wire m0_ar_unmapped, m1_ar_unmapped;

    integer errors;

    axi4_crossbar_ar_router DUT (
        .aclk(aclk),
        .aresetn(aresetn),

        .m0_arid(m0_arid),
        .m0_araddr(m0_araddr),
        .m0_arlen(m0_arlen),
        .m0_arsize(m0_arsize),
        .m0_arburst(m0_arburst),
        .m0_arlock(m0_arlock),
        .m0_arcache(m0_arcache),
        .m0_arprot(m0_arprot),
        .m0_arqos(m0_arqos),
        .m0_arregion(m0_arregion),
        .m0_arvalid(m0_arvalid),
        .m0_arready(m0_arready),

        .m1_arid(m1_arid),
        .m1_araddr(m1_araddr),
        .m1_arlen(m1_arlen),
        .m1_arsize(m1_arsize),
        .m1_arburst(m1_arburst),
        .m1_arlock(m1_arlock),
        .m1_arcache(m1_arcache),
        .m1_arprot(m1_arprot),
        .m1_arqos(m1_arqos),
        .m1_arregion(m1_arregion),
        .m1_arvalid(m1_arvalid),
        .m1_arready(m1_arready),

        .s0_arid(s0_arid),
        .s0_araddr(s0_araddr),
        .s0_arlen(s0_arlen),
        .s0_arsize(s0_arsize),
        .s0_arburst(s0_arburst),
        .s0_arlock(s0_arlock),
        .s0_arcache(s0_arcache),
        .s0_arprot(s0_arprot),
        .s0_arqos(s0_arqos),
        .s0_arregion(s0_arregion),
        .s0_arvalid(s0_arvalid),
        .s0_arready(s0_arready),

        .s1_arid(s1_arid),
        .s1_araddr(s1_araddr),
        .s1_arlen(s1_arlen),
        .s1_arsize(s1_arsize),
        .s1_arburst(s1_arburst),
        .s1_arlock(s1_arlock),
        .s1_arcache(s1_arcache),
        .s1_arprot(s1_arprot),
        .s1_arqos(s1_arqos),
        .s1_arregion(s1_arregion),
        .s1_arvalid(s1_arvalid),
        .s1_arready(s1_arready),

        .m0_read_available(m0_read_available),
        .m1_read_available(m1_read_available),

        .s0_rd_req(s0_rd_req),
        .s0_rd_grant(s0_rd_grant),
        .s0_rd_enable(s0_rd_enable),

        .s1_rd_req(s1_rd_req),
        .s1_rd_grant(s1_rd_grant),
        .s1_rd_enable(s1_rd_enable),

        .s0_rd_grant_accept(s0_rd_grant_accept),
        .s1_rd_grant_accept(s1_rd_grant_accept),

        .m0_ar_unmapped(m0_ar_unmapped),
        .m1_ar_unmapped(m1_ar_unmapped)
    );

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    task check;
        input condition;
        input [255:0] test_name;
        begin
            #1;
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
            m0_arvalid = 0;
            m1_arvalid = 0;
            m0_araddr = 0;
            m1_araddr = 0;
            m0_read_available = 1;
            m1_read_available = 1;
        end
    endtask

    initial begin

        errors = 0;

        aresetn = 0;

        m0_arid = 4'h1;
        m0_araddr = 0;
        m0_arlen = 8'd3;
        m0_arsize = 3'd2;
        m0_arburst = 2'b01;
        m0_arlock = 0;
        m0_arcache = 0;
        m0_arprot = 0;
        m0_arqos = 0;
        m0_arregion = 0;
        m0_arvalid = 0;

        m1_arid = 4'h2;
        m1_araddr = 0;
        m1_arlen = 8'd7;
        m1_arsize = 3'd2;
        m1_arburst = 2'b01;
        m1_arlock = 0;
        m1_arcache = 0;
        m1_arprot = 0;
        m1_arqos = 0;
        m1_arregion = 0;
        m1_arvalid = 0;

        s0_arready = 0;
        s1_arready = 0;

        s0_rd_grant = 0;
        s1_rd_grant = 0;
        s0_rd_enable = 1;
        s1_rd_enable = 1;

        clear_masters();

        repeat (2) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        $display("\nAXI4 CROSSBAR AR ROUTER TEST STARTED\n");

        // TEST 1: M0 to S0
        m0_arvalid = 1;
        m0_araddr = 32'h00001234;
        s0_rd_grant = 2'b01;
        s0_arready = 1;

        #1;
        check(s0_rd_req == 2'b01 &&
              s0_arvalid && s0_araddr == 32'h00001234 &&
              s0_arid == 4'h1 && m0_arready && !m1_arready,
              "M0 routed to S0");

        // TEST 2: M0 to S1
        clear_masters();
        s0_rd_grant = 0;
        m0_arvalid = 1;
        m0_araddr = 32'h00010020;
        s1_rd_grant = 2'b01;
        s1_arready = 1;

        #1;
        check(s1_rd_req == 2'b01 &&
              s1_arvalid && s1_araddr == 32'h00010020 &&
              m0_arready && !m1_arready,
              "M0 routed to S1");

        // TEST 3: M1 to S0
        clear_masters();
        s1_rd_grant = 0;
        m1_arvalid = 1;
        m1_araddr = 32'h0000ABCD;
        s0_rd_grant = 2'b10;
        s0_arready = 1;

        #1;
        check(s0_rd_req == 2'b10 &&
              s0_arvalid && s0_araddr == 32'h0000ABCD &&
              s0_arid == 4'h2 && m1_arready && !m0_arready,
              "M1 routed to S0");

        // TEST 4: M1 to S1
        clear_masters();
        s0_rd_grant = 0;
        m1_arvalid = 1;
        m1_araddr = 32'h0001ABCD;
        s1_rd_grant = 2'b10;
        s1_arready = 1;

        #1;
        check(s1_rd_req == 2'b10 &&
              s1_arvalid && s1_araddr == 32'h0001ABCD &&
              s1_arid == 4'h2 && m1_arready && !m0_arready,
              "M1 routed to S1");

        // TEST 5: Simultaneous requests to different slaves
        clear_masters();
        s1_rd_grant = 0;

        m0_arvalid = 1;
        m0_araddr = 32'h00000080;

        m1_arvalid = 1;
        m1_araddr = 32'h00010080;

        s0_rd_grant = 2'b01;
        s1_rd_grant = 2'b10;
        s0_arready = 1;
        s1_arready = 1;

        #1;
        check(s0_arvalid && s1_arvalid &&
              m0_arready && m1_arready &&
              s0_araddr == 32'h00000080 &&
              s1_araddr == 32'h00010080,
              "Simultaneous M0-to-S0 and M1-to-S1");

        // TEST 6: Same-slave contention, M0 wins
        clear_masters();

        m0_arvalid = 1;
        m0_araddr = 32'h00000040;

        m1_arvalid = 1;
        m1_araddr = 32'h00000060;

        s0_rd_grant = 2'b01;
        s1_rd_grant = 0;
        s0_arready = 1;

        #1;
        check(s0_rd_req == 2'b11 &&
              s0_arvalid &&
              s0_araddr == 32'h00000040 &&
              m0_arready && !m1_arready,
              "S0 contention: M0 grant selected");

        // TEST 7: Slave backpressure
        s0_arready = 0;

        #1;
        check(s0_arvalid &&
              s0_araddr == 32'h00000040 &&
              !m0_arready,
              "S0 backpressure holds ARVALID and payload");

        // TEST 8: Unmapped address
        clear_masters();
        s0_rd_grant = 0;

        m0_arvalid = 1;
        m0_araddr = 32'h00020000;

        #1;
        check(m0_ar_unmapped &&
              s0_rd_req == 2'b00 &&
              s1_rd_req == 2'b00 &&
              !s0_arvalid && !s1_arvalid,
              "Unmapped address detected");

        // TEST 9: Master unavailable
        clear_masters();

        m0_read_available = 0;
        m0_arvalid = 1;
        m0_araddr = 32'h00000020;

        s0_rd_grant = 2'b01;

        #1;
        check(s0_rd_req == 2'b00 &&
              !s0_arvalid && !m0_arready,
              "Unavailable master is blocked");

        // TEST 10: Grant acceptance handshake
        clear_masters();

        m0_arvalid = 1;
        m0_araddr = 32'h00000020;
        s0_rd_grant = 2'b01;
        s0_arready = 1;

        #1;
        check(s0_rd_grant_accept,
              "S0 grant accepted only on AR handshake");

        if (errors == 0)
            $display("\nALL AR ROUTER TESTS PASSED!");
        else
            $display("\nAR ROUTER TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule
