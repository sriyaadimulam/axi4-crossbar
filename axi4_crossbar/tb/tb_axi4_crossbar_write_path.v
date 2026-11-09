
`timescale 1ns / 1ps

module tb_axi4_crossbar_write_path;

    reg aclk;
    reg aresetn;
    reg [1:0] arb_policy;

    // Master availability model
    reg m0_write_available;
    reg m1_write_available;

    // Master 0 AW interface
    reg [3:0] m0_awid;
    reg [31:0] m0_awaddr;
    reg [7:0] m0_awlen;
    reg [2:0] m0_awsize;
    reg [1:0] m0_awburst;
    reg m0_awlock;
    reg [3:0] m0_awcache;
    reg [2:0] m0_awprot;
    reg [3:0] m0_awqos;
    reg [3:0] m0_awregion;
    reg m0_awvalid;
    wire m0_awready;

    // Master 1 AW interface
    reg [3:0] m1_awid;
    reg [31:0] m1_awaddr;
    reg [7:0] m1_awlen;
    reg [2:0] m1_awsize;
    reg [1:0] m1_awburst;
    reg m1_awlock;
    reg [3:0] m1_awcache;
    reg [2:0] m1_awprot;
    reg [3:0] m1_awqos;
    reg [3:0] m1_awregion;
    reg m1_awvalid;
    wire m1_awready;

    // Slave 0 AW interface
    wire [3:0] s0_awid;
    wire [31:0] s0_awaddr;
    wire [7:0] s0_awlen;
    wire [2:0] s0_awsize;
    wire [1:0] s0_awburst;
    wire s0_awlock;
    wire [3:0] s0_awcache;
    wire [2:0] s0_awprot;
    wire [3:0] s0_awqos;
    wire [3:0] s0_awregion;
    wire s0_awvalid;
    reg s0_awready;

    // Slave 1 AW interface
    wire [3:0] s1_awid;
    wire [31:0] s1_awaddr;
    wire [7:0] s1_awlen;
    wire [2:0] s1_awsize;
    wire [1:0] s1_awburst;
    wire s1_awlock;
    wire [3:0] s1_awcache;
    wire [2:0] s1_awprot;
    wire [3:0] s1_awqos;
    wire [3:0] s1_awregion;
    wire s1_awvalid;
    reg s1_awready;

    // =================================================
    // W CHANNEL SIGNALS
    // =================================================

    // Master 0 W
    reg [31:0] m0_wdata;
    reg [3:0]  m0_wstrb;
    reg        m0_wlast;
    reg        m0_wvalid;
    wire       m0_wready;

    // Master 1 W
    reg [31:0] m1_wdata;
    reg [3:0]  m1_wstrb;
    reg        m1_wlast;
    reg        m1_wvalid;
    wire       m1_wready;

    // Slave 0 W
    wire [31:0] s0_wdata;
    wire [3:0]  s0_wstrb;
    wire        s0_wlast;
    wire        s0_wvalid;
    reg         s0_wready;

    // Slave 1 W
    wire [31:0] s1_wdata;
    wire [3:0]  s1_wstrb;
    wire        s1_wlast;
    wire        s1_wvalid;
    reg         s1_wready;

    // Master B interfaces
    wire [3:0] m0_bid;
    wire [1:0] m0_bresp;
    wire m0_bvalid;
    reg m0_bready;

    wire [3:0] m1_bid;
    wire [1:0] m1_bresp;
    wire m1_bvalid;
    reg m1_bready;

    // Slave B interfaces
    reg [3:0] s0_bid;
    reg [1:0] s0_bresp;
    reg s0_bvalid;
    wire s0_bready;

    reg [3:0] s1_bid;
    reg [1:0] s1_bresp;
    reg s1_bvalid;
    wire s1_bready;

    // Burst-age arbitration inputs
    reg s0_wr_service_valid;
    reg s0_wr_service_master;
    reg s0_wr_epoch_clear;

    reg s1_wr_service_valid;
    reg s1_wr_service_master;
    reg s1_wr_epoch_clear;

    // Master tracker events
    wire m0_aw_accept;
    wire m1_aw_accept;
    wire m0_write_complete;
    wire m1_write_complete;

    // Slave write-slot status
    wire s0_write_slot_available;
    wire s1_write_slot_available;

    // Unmapped address indications
    wire m0_aw_unmapped;
    wire m1_aw_unmapped;

    integer pass_count;
    integer fail_count;

    // =================================================
    // DUT
    // =================================================

    axi4_crossbar_write_path #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .ID_WIDTH(4)
    ) DUT (

        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        .m0_write_available(m0_write_available),
        .m1_write_available(m1_write_available),

        // M0 AW
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

        // M1 AW
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

        // S0 AW
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

        // S1 AW
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
        // M0 W
        .m0_wdata(m0_wdata),
        .m0_wstrb(m0_wstrb),
        .m0_wlast(m0_wlast),
        .m0_wvalid(m0_wvalid),
        .m0_wready(m0_wready),

        // M1 W
        .m1_wdata(m1_wdata),
        .m1_wstrb(m1_wstrb),
        .m1_wlast(m1_wlast),
        .m1_wvalid(m1_wvalid),
        .m1_wready(m1_wready),

        // S0 W
        .s0_wdata(s0_wdata),
        .s0_wstrb(s0_wstrb),
        .s0_wlast(s0_wlast),
        .s0_wvalid(s0_wvalid),
        .s0_wready(s0_wready),

        // S1 W
        .s1_wdata(s1_wdata),
        .s1_wstrb(s1_wstrb),
        .s1_wlast(s1_wlast),
        .s1_wvalid(s1_wvalid),
        .s1_wready(s1_wready),

        // M0 B
        .m0_bid(m0_bid),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),

        // M1 B
        .m1_bid(m1_bid),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),

        // S0 B
        .s0_bid(s0_bid),
        .s0_bresp(s0_bresp),
        .s0_bvalid(s0_bvalid),
        .s0_bready(s0_bready),

        // S1 B
        .s1_bid(s1_bid),
        .s1_bresp(s1_bresp),
        .s1_bvalid(s1_bvalid),
        .s1_bready(s1_bready),

        // Age arbitration
        .s0_wr_service_valid(s0_wr_service_valid),
        .s0_wr_service_master(s0_wr_service_master),
        .s0_wr_epoch_clear(s0_wr_epoch_clear),

        .s1_wr_service_valid(s1_wr_service_valid),
        .s1_wr_service_master(s1_wr_service_master),
        .s1_wr_epoch_clear(s1_wr_epoch_clear),

        // Tracker events
        .m0_aw_accept(m0_aw_accept),
        .m1_aw_accept(m1_aw_accept),
        .m0_write_complete(m0_write_complete),
        .m1_write_complete(m1_write_complete),

        // Slot availability
        .s0_write_slot_available(s0_write_slot_available),
        .s1_write_slot_available(s1_write_slot_available),

        // Unmapped
        .m0_aw_unmapped(m0_aw_unmapped),
        .m1_aw_unmapped(m1_aw_unmapped)
    );

    // =================================================
    // Clock generation
    // =================================================

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // =================================================
    // Simple master tracker model
    // =================================================

    // Availability is updated at the active clock edge.
    // The real shared master_tracker will be connected
    // during top-level integration.

    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            m0_write_available <= 1'b1;
            m1_write_available <= 1'b1;
        end

        else begin

            if (m0_aw_accept)
                m0_write_available <= 1'b0;
            else if (m0_write_complete)
                m0_write_available <= 1'b1;

            if (m1_aw_accept)
                m1_write_available <= 1'b0;
            else if (m1_write_complete)
                m1_write_available <= 1'b1;

        end
    end

    // =================================================
    // Test checking task
    // =================================================

    task check;
        input condition;
        input [8*70-1:0] test_name;

        begin
            if (condition === 1'b1) begin
                $display("PASS: %0s", test_name);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: %0s", test_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task clear_master_requests;
        begin
            m0_awvalid = 0;
            m1_awvalid = 0;
        end
    endtask

    // =================================================
    // Main stimulus
    // =================================================

    initial begin

        pass_count = 0;
        fail_count = 0;

        aresetn = 0;
        arb_policy = 2'b00;

        m0_write_available = 1;
        m1_write_available = 1;

        // M0 AW initialization
        m0_awid = 0;
        m0_awaddr = 0;
        m0_awlen = 0;
        m0_awsize = 2;
        m0_awburst = 1;
        m0_awlock = 0;
        m0_awcache = 0;
        m0_awprot = 0;
        m0_awqos = 0;
        m0_awregion = 0;
        m0_awvalid = 0;

        // M1 AW initialization
        m1_awid = 0;
        m1_awaddr = 0;
        m1_awlen = 0;
        m1_awsize = 2;
        m1_awburst = 1;
        m1_awlock = 0;
        m1_awcache = 0;
        m1_awprot = 0;
        m1_awqos = 0;
        m1_awregion = 0;
        m1_awvalid = 0;

        s0_awready = 1;
        s1_awready = 1;

        // W channel initialization
        m0_wdata  = 0;
        m0_wstrb  = 0;
        m0_wlast  = 0;
        m0_wvalid = 0;

        m1_wdata  = 0;
        m1_wstrb  = 0;
        m1_wlast  = 0;
        m1_wvalid = 0;

        s0_wready = 1;
        s1_wready = 1;

        m0_bready = 0;
        m1_bready = 0;

        s0_bid = 0;
        s1_bid = 0;
        s0_bresp = 0;
        s1_bresp = 0;
        s0_bvalid = 0;
        s1_bvalid = 0;

        s0_wr_service_valid = 0;
        s0_wr_service_master = 0;
        s0_wr_epoch_clear = 0;

        s1_wr_service_valid = 0;
        s1_wr_service_master = 0;
        s1_wr_epoch_clear = 0;

        repeat (2) @(posedge aclk);
        @(negedge aclk);

        aresetn = 1;

        $display("==============================================");
        $display(" AXI4 WRITE PATH TEST STARTED");
        $display("==============================================");

        // =============================================
        // TEST 1: M0 writes to S0
        // =============================================

        m0_awid = 4'h3;
        m0_awaddr = 32'h00000020;
        m0_awvalid = 1;

        #1;

        check(s0_awvalid && s0_awaddr == 32'h00000020,
              "M0 address routed to S0");

        // Check handshake BEFORE rising edge
        check(m0_aw_accept && m0_awready,
              "M0 AW handshake detected");

        @(posedge aclk);
        #1;

        // Check registered state AFTER rising edge
        check(!m0_write_available &&
              !s0_write_slot_available,
              "M0 AW accepted and write slots updated");

        @(negedge aclk);
        clear_master_requests();

        // M0 sends W data to S0
        m0_wdata  = 32'hAABBCCDD;
        m0_wstrb  = 4'b1111;
        m0_wlast  = 1'b1;
        m0_wvalid = 1'b1;

        s0_wready = 1'b0;

        #1;

        check(s0_wvalid &&
              s0_wdata == 32'hAABBCCDD &&
              s0_wstrb == 4'b1111 &&
              s0_wlast &&
              !m0_wready,
              "M0 W data routed to S0 and held under backpressure");

        @(negedge aclk);
        s0_wready = 1'b1;

        #1;

        check(s0_wvalid && m0_wready,
              "M0 W handshake ready");

        @(posedge aclk);
        #1;

        check(!s0_wvalid,
              "S0 W ownership released after accepted WLAST");

        @(negedge aclk);
        m0_wvalid = 1'b0;
        m0_wlast  = 1'b0;

        // M0 must not issue another write while outstanding
        m0_awaddr = 32'h00000040;
        m0_awvalid = 1;

        #1;

        check(!s0_awvalid && !m0_awready,
              "M0 blocked while previous write is outstanding");

        @(negedge aclk);
        clear_master_requests();

        // M0 B response under backpressure
        s0_bid = 4'h3;
        s0_bresp = 2'b00;
        s0_bvalid = 1;
        m0_bready = 0;

        #1;

        check(m0_bvalid && !s0_bready &&
              m0_bid == 4'h3,
              "M0 B response held under backpressure");

        // Release backpressure
        @(negedge aclk);
        m0_bready = 1;

        #1;

        check(m0_bvalid && m0_bready &&
              m0_write_complete,
              "M0 B handshake detected");

        @(posedge aclk);
        #1;

        check(m0_write_available &&
              s0_write_slot_available,
              "M0 B handshake completes write and releases S0");

        @(negedge aclk);
        s0_bvalid = 0;
        m0_bready = 0;

        // =============================================
        // TEST 2: M1 writes to S1
        // =============================================

        m1_awid = 4'h7;
        m1_awaddr = 32'h00010040;
        m1_awvalid = 1;

        #1;

        check(s1_awvalid && s1_awaddr == 32'h00010040,
              "M1 address routed to S1");

        check(m1_aw_accept && m1_awready,
              "M1 AW handshake detected");

        @(posedge aclk);
        #1;

        check(!m1_write_available &&
              !s1_write_slot_available,
              "M1 AW accepted and S1 slot occupied");

        @(negedge aclk);
        clear_master_requests();

        // M1 sends W data to S1
        m1_wdata  = 32'h12345678;
        m1_wstrb  = 4'b1010;
        m1_wlast  = 1'b1;
        m1_wvalid = 1'b1;

        #1;

        check(s1_wvalid &&
              s1_wdata == 32'h12345678 &&
              s1_wstrb == 4'b1010 &&
              s1_wlast &&
              m1_wready,
              "M1 W data routed correctly to S1");

        @(posedge aclk);
        #1;

        check(!s1_wvalid,
              "S1 W ownership released after accepted WLAST");

        @(negedge aclk);
        m1_wvalid = 1'b0;
        m1_wlast  = 1'b0;

        // M1 B response
        s1_bid = 4'h7;
        s1_bresp = 2'b00;
        s1_bvalid = 1;
        m1_bready = 1;

        #1;

        check(m1_bvalid && m1_bready &&
              m1_bid == 4'h7 &&
              m1_write_complete,
              "M1 B response routed and handshake detected");

        @(posedge aclk);
        #1;

        check(m1_write_available &&
              s1_write_slot_available,
              "M1 write completed and S1 slot released");

        @(negedge aclk);
        s1_bvalid = 0;
        m1_bready = 0;

        // =============================================
        // TEST 3: Simultaneous M0->S0 and M1->S1
        // =============================================

        m0_awid = 4'h1;
        m0_awaddr = 32'h00000080;
        m0_awvalid = 1;

        m1_awid = 4'h2;
        m1_awaddr = 32'h00010080;
        m1_awvalid = 1;

        #1;

        check(s0_awvalid && s1_awvalid &&
              s0_awid == 4'h1 &&
              s1_awid == 4'h2,
              "Simultaneous writes routed to different slaves");

        check(m0_aw_accept && m1_aw_accept,
              "Both simultaneous AW handshakes detected");

        @(posedge aclk);
        #1;

        check(!m0_write_available &&
              !m1_write_available &&
              !s0_write_slot_available &&
              !s1_write_slot_available,
              "Both simultaneous transactions accepted");

        @(negedge aclk);
        clear_master_requests();

        // Simultaneous W transfers
        m0_wdata  = 32'hAAAA0001;
        m0_wstrb  = 4'b1111;
        m0_wlast  = 1'b1;
        m0_wvalid = 1'b1;

        m1_wdata  = 32'hBBBB0002;
        m1_wstrb  = 4'b1100;
        m1_wlast  = 1'b1;
        m1_wvalid = 1'b1;

        #1;

        check(s0_wvalid && s1_wvalid &&
              s0_wdata == 32'hAAAA0001 &&
              s1_wdata == 32'hBBBB0002 &&
              m0_wready && m1_wready,
              "Simultaneous W transfers routed independently");

        @(posedge aclk);
        #1;

        check(!s0_wvalid && !s1_wvalid,
              "Both W ownership slots released after WLAST");

        @(negedge aclk);
        m0_wvalid = 1'b0;
        m1_wvalid = 1'b0;
        m0_wlast  = 1'b0;
        m1_wlast  = 1'b0;

        // Simultaneous B responses
        s0_bid = 4'h1;
        s1_bid = 4'h2;

        s0_bresp = 2'b00;
        s1_bresp = 2'b00;

        s0_bvalid = 1;
        s1_bvalid = 1;

        m0_bready = 1;
        m1_bready = 1;

        #1;

        check(m0_bvalid && m1_bvalid &&
              m0_bid == 4'h1 &&
              m1_bid == 4'h2,
              "Simultaneous B responses routed to correct masters");

        check(m0_write_complete && m1_write_complete,
              "Both B handshakes detected");

        @(posedge aclk);
        #1;

        check(m0_write_available &&
              m1_write_available &&
              s0_write_slot_available &&
              s1_write_slot_available,
              "Both slave write slots released");

        @(negedge aclk);
        s0_bvalid = 0;
        s1_bvalid = 0;
        m0_bready = 0;
        m1_bready = 0;

        // =============================================
        // TEST 4: Same-slave contention
        // Fixed priority: M0 wins
        // =============================================

        m0_awaddr = 32'h000000A0;
        m1_awaddr = 32'h000000B0;

        m0_awid = 4'h4;
        m1_awid = 4'h5;

        m0_awvalid = 1;
        m1_awvalid = 1;

        s0_awready = 0;

        #1;

        check(s0_awvalid && s0_awid == 4'h4 &&
              !m0_awready && !m1_awready,
              "Fixed priority selects M0 under S0 backpressure");

        @(posedge aclk);
        #1;

        check(s0_awvalid && s0_awid == 4'h4,
              "M0 AW payload remains stable during backpressure");

        // Release slave backpressure
        @(negedge aclk);
        s0_awready = 1;

        #1;

        check(m0_aw_accept && m0_awready,
              "M0 contention AW handshake detected");

        @(posedge aclk);
        #1;

        check(!m0_write_available &&
              !s0_write_slot_available,
              "M0 contention request accepted first");

        @(negedge aclk);
        clear_master_requests();

                // M0 sends W data to S0
        m0_wdata  = 32'hFACE0001;
        m0_wstrb  = 4'b1111;
        m0_wlast  = 1'b1;
        m0_wvalid = 1'b1;

        #1;

        check(s0_wvalid &&
              s0_wdata == 32'hFACE0001 &&
              m0_wready,
              "M0 contention W data routed to S0");

        @(posedge aclk);
        #1;

        check(!s0_wvalid,
              "M0 contention W transaction completed");

        @(negedge aclk);
        m0_wvalid = 1'b0;
        m0_wlast  = 1'b0;

        // Complete M0 B response
        s0_bid = 4'h4;
        s0_bresp = 2'b00;
        s0_bvalid = 1;
        m0_bready = 1;

        #1;

        check(m0_bvalid && m0_bready &&
              m0_write_complete,
              "M0 contention B handshake detected");

        @(posedge aclk);
        #1;

        check(m0_write_available &&
              s0_write_slot_available,
              "M0 contention transaction completed");

        @(negedge aclk);
        s0_bvalid = 0;
        m0_bready = 0;

        // M1 should now receive S0
        m1_awvalid = 1;

        #1;

        check(s0_awvalid && s0_awid == 4'h5,
              "M1 receives S0 after M0 transaction completes");

        check(m1_aw_accept && m1_awready,
              "M1 AW handshake detected");

        @(posedge aclk);
        #1;

        check(!m1_write_available &&
              !s0_write_slot_available,
              "M1 AW transaction accepted");

        @(negedge aclk);
        clear_master_requests();

                // M1 sends W data to S0
        m1_wdata  = 32'hFACE0002;
        m1_wstrb  = 4'b1111;
        m1_wlast  = 1'b1;
        m1_wvalid = 1'b1;

        #1;

        check(s0_wvalid &&
              s0_wdata == 32'hFACE0002 &&
              m1_wready,
              "M1 contention W data routed to S0");

        @(posedge aclk);
        #1;

        check(!s0_wvalid,
              "M1 contention W transaction completed");

        @(negedge aclk);
        m1_wvalid = 1'b0;
        m1_wlast  = 1'b0;

        // Complete M1 B response
        s0_bid = 4'h5;
        s0_bresp = 2'b00;
        s0_bvalid = 1;
        m1_bready = 1;

        #1;

        check(m1_bvalid && m1_bready &&
              m1_write_complete,
              "M1 B handshake detected");

        @(posedge aclk);
        #1;

        check(m1_write_available &&
              s0_write_slot_available,
              "M1 response completes and releases S0");

        @(negedge aclk);
        s0_bvalid = 0;
        m1_bready = 0;

        // =============================================
        // TEST 5: Unmapped address detection
        // =============================================

        m0_awaddr = 32'h00020000;
        m0_awvalid = 1;

        #1;

        check(m0_aw_unmapped &&
              !s0_awvalid &&
              !s1_awvalid,
              "Unmapped address detected without slave AW");

        @(negedge aclk);
        clear_master_requests();

        // =============================================
        // SUMMARY
        // =============================================

        $display("----------------------------------------------");
        $display(" AXI4 WRITE PATH TEST SUMMARY");
        $display(" PASSED : %0d", pass_count);
        $display(" FAILED : %0d", fail_count);
        $display("----------------------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        #20;
        $finish;

    end

endmodule
