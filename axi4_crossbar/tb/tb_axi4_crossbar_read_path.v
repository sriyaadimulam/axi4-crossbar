
`timescale 1ns / 1ps

module tb_axi4_crossbar_read_path;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH   = 4;

    localparam [1:0] FIXED_PRIORITY = 2'b00;
    localparam [1:0] DECERR = 2'b11;

    // =================================================
    // CLOCK AND RESET
    // =================================================

    reg aclk;
    reg aresetn;

    initial begin
        aclk = 1'b0;
        forever #5 aclk = ~aclk;
    end

    // =================================================
    // ARBITRATION POLICY
    // =================================================

    reg [1:0] arb_policy;

    // =================================================
    // MASTER 0 AR
    // =================================================

    reg [ID_WIDTH-1:0] m0_arid;
    reg [ADDR_WIDTH-1:0] m0_araddr;
    reg [7:0] m0_arlen;
    reg [2:0] m0_arsize;
    reg [1:0] m0_arburst;
    reg m0_arlock;
    reg [3:0] m0_arcache;
    reg [2:0] m0_arprot;
    reg [3:0] m0_arqos;
    reg [3:0] m0_arregion;
    reg m0_arvalid;
    wire m0_arready;

    // =================================================
    // MASTER 1 AR
    // =================================================

    reg [ID_WIDTH-1:0] m1_arid;
    reg [ADDR_WIDTH-1:0] m1_araddr;
    reg [7:0] m1_arlen;
    reg [2:0] m1_arsize;
    reg [1:0] m1_arburst;
    reg m1_arlock;
    reg [3:0] m1_arcache;
    reg [2:0] m1_arprot;
    reg [3:0] m1_arqos;
    reg [3:0] m1_arregion;
    reg m1_arvalid;
    wire m1_arready;

    // =================================================
    // SLAVE 0 AR
    // =================================================

    wire [ID_WIDTH-1:0] s0_arid;
    wire [ADDR_WIDTH-1:0] s0_araddr;
    wire [7:0] s0_arlen;
    wire [2:0] s0_arsize;
    wire [1:0] s0_arburst;
    wire s0_arlock;
    wire [3:0] s0_arcache;
    wire [2:0] s0_arprot;
    wire [3:0] s0_arqos;
    wire [3:0] s0_arregion;
    wire s0_arvalid;
    reg s0_arready;

    // =================================================
    // SLAVE 1 AR
    // =================================================

    wire [ID_WIDTH-1:0] s1_arid;
    wire [ADDR_WIDTH-1:0] s1_araddr;
    wire [7:0] s1_arlen;
    wire [2:0] s1_arsize;
    wire [1:0] s1_arburst;
    wire s1_arlock;
    wire [3:0] s1_arcache;
    wire [2:0] s1_arprot;
    wire [3:0] s1_arqos;
    wire [3:0] s1_arregion;
    wire s1_arvalid;
    reg s1_arready;

    // =================================================
    // SLAVE 0 R
    // =================================================

    reg [ID_WIDTH-1:0] s0_rid;
    reg [DATA_WIDTH-1:0] s0_rdata;
    reg [1:0] s0_rresp;
    reg s0_rlast;
    reg s0_rvalid;
    wire s0_rready;

    // =================================================
    // SLAVE 1 R
    // =================================================

    reg [ID_WIDTH-1:0] s1_rid;
    reg [DATA_WIDTH-1:0] s1_rdata;
    reg [1:0] s1_rresp;
    reg s1_rlast;
    reg s1_rvalid;
    wire s1_rready;

    // =================================================
    // MASTER 0 R
    // =================================================

    wire [ID_WIDTH-1:0] m0_rid;
    wire [DATA_WIDTH-1:0] m0_rdata;
    wire [1:0] m0_rresp;
    wire m0_rlast;
    wire m0_rvalid;
    reg m0_rready;

    // =================================================
    // MASTER 1 R
    // =================================================

    wire [ID_WIDTH-1:0] m1_rid;
    wire [DATA_WIDTH-1:0] m1_rdata;
    wire [1:0] m1_rresp;
    wire m1_rlast;
    wire m1_rvalid;
    reg m1_rready;

    // =================================================
    // MASTER TRACKER
    // =================================================

    reg m0_read_available;
    reg m1_read_available;

    wire m0_ar_accept;
    wire m1_ar_accept;

    wire m0_read_complete;
    wire m1_read_complete;

    // =================================================
    // AGE ARBITRATION SERVICE
    // =================================================

    reg s0_rd_service_valid;
    reg s0_rd_service_master;
    reg s0_rd_epoch_clear;

    reg s1_rd_service_valid;
    reg s1_rd_service_master;
    reg s1_rd_epoch_clear;

    // =================================================
    // SLAVE OWNERSHIP
    // =================================================

    wire s0_read_active;
    wire s1_read_active;

    // =================================================
    // DECERR INTERFACE
    // =================================================

    wire [ID_WIDTH-1:0] decerr_arid;
    wire [7:0] decerr_arlen;
    wire decerr_arvalid;
    wire decerr_arready;

    wire [ID_WIDTH-1:0] decerr_rid;
    wire [DATA_WIDTH-1:0] decerr_rdata;
    wire [1:0] decerr_rresp;
    wire decerr_rlast;
    wire decerr_rvalid;
    wire decerr_rready;

    // =================================================
    // DUT: READ PATH
    // =================================================

    axi4_crossbar_read_path #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) DUT (

        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

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

        .m0_read_available(m0_read_available),
        .m1_read_available(m1_read_available),

        .m0_ar_accept(m0_ar_accept),
        .m1_ar_accept(m1_ar_accept),

        .m0_read_complete(m0_read_complete),
        .m1_read_complete(m1_read_complete),

        .s0_rd_service_valid(s0_rd_service_valid),
        .s0_rd_service_master(s0_rd_service_master),
        .s0_rd_epoch_clear(s0_rd_epoch_clear),

        .s1_rd_service_valid(s1_rd_service_valid),
        .s1_rd_service_master(s1_rd_service_master),
        .s1_rd_epoch_clear(s1_rd_epoch_clear),

        .s0_read_active(s0_read_active),
        .s1_read_active(s1_read_active),

        .decerr_arid(decerr_arid),
        .decerr_arlen(decerr_arlen),
        .decerr_arvalid(decerr_arvalid),
        .decerr_arready(decerr_arready),

        .decerr_rid(decerr_rid),
        .decerr_rdata(decerr_rdata),
        .decerr_rresp(decerr_rresp),
        .decerr_rlast(decerr_rlast),
        .decerr_rvalid(decerr_rvalid),
        .decerr_rready(decerr_rready)
    );

    // =================================================
    // DECERR HANDLER
    // =================================================

    axi4_crossbar_decerr_handler #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) DUT_DECERR (

        .aclk(aclk),
        .aresetn(aresetn),

        .m_arid(decerr_arid),
        .m_arlen(decerr_arlen),
        .m_arvalid(decerr_arvalid),
        .m_arready(decerr_arready),

        .m_rid(decerr_rid),
        .m_rdata(decerr_rdata),
        .m_rresp(decerr_rresp),
        .m_rlast(decerr_rlast),
        .m_rvalid(decerr_rvalid),
        .m_rready(decerr_rready),

        .m_awid({ID_WIDTH{1'b0}}),
        .m_awlen(8'd0),
        .m_awvalid(1'b0),
        .m_awready(),

        .m_wdata({DATA_WIDTH{1'b0}}),
        .m_wstrb({(DATA_WIDTH/8){1'b0}}),
        .m_wlast(1'b0),
        .m_wvalid(1'b0),
        .m_wready(),

        .m_bid(),
        .m_bresp(),
        .m_bvalid(),
        .m_bready(1'b0)
    );

    // =================================================
    // TEST COUNTERS AND TIMEOUT
    // =================================================

    integer pass_count;
    integer fail_count;
    integer wait_count;

    // =================================================
    // INITIALIZATION AND TEST SEQUENCE
    // =================================================

    initial begin

        aresetn = 1'b0;
        arb_policy = FIXED_PRIORITY;

        m0_arid = 0;
        m0_araddr = 0;
        m0_arlen = 0;
        m0_arsize = 3'b010;
        m0_arburst = 2'b01;
        m0_arlock = 0;
        m0_arcache = 0;
        m0_arprot = 0;
        m0_arqos = 0;
        m0_arregion = 0;
        m0_arvalid = 0;

        m1_arid = 0;
        m1_araddr = 0;
        m1_arlen = 0;
        m1_arsize = 3'b010;
        m1_arburst = 2'b01;
        m1_arlock = 0;
        m1_arcache = 0;
        m1_arprot = 0;
        m1_arqos = 0;
        m1_arregion = 0;
        m1_arvalid = 0;

        s0_arready = 0;
        s1_arready = 0;

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

        m0_read_available = 1;
        m1_read_available = 1;

        s0_rd_service_valid = 0;
        s0_rd_service_master = 0;
        s0_rd_epoch_clear = 0;

        s1_rd_service_valid = 0;
        s1_rd_service_master = 0;
        s1_rd_epoch_clear = 0;

        pass_count = 0;
        fail_count = 0;

        $display("==============================================");
        $display(" AXI4 CROSSBAR READ PATH TEST STARTED");
        $display("==============================================");

        // Reset
        repeat (4) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1'b1;
        repeat (2) @(posedge aclk);

        // =========================================
        // TEST 1: M0 -> SLAVE 0
        // =========================================

        $display("\nTEST 1: M0 -> SLAVE 0");

        @(negedge aclk);

        m0_arid = 4'h1;
        m0_araddr = 32'h00000020;
        m0_arlen = 0;
        m0_arvalid = 1;
        s0_arready = 1;

        // Wait for combinational logic to settle.
        #1;

        wait_count = 0;

        while ((m0_arready !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        if (m0_arready === 1'b1 &&
            s0_arvalid === 1'b1 &&
            s0_arready === 1'b1 &&
            s0_arid == 4'h1 &&
            s0_araddr == 32'h00000020 &&
            m0_ar_accept === 1'b1) begin

            $display("PASS: M0 address routed to S0");
            pass_count = pass_count + 1;

            // Complete handshake.
            @(posedge aclk);
            #1;
        end
        else begin
            $display("FAIL: M0 -> S0 address handshake");
            fail_count = fail_count + 1;
        end

        @(negedge aclk);
        m0_arvalid = 0;
        s0_arready = 0;

      
        // Send one response beat from S0.
        // Keep master not-ready initially so that
        // the response can be checked before handshake.

        m0_rready = 0;

        @(negedge aclk);
        s0_rid = 4'h1;
        s0_rdata = 32'h12345678;
        s0_rresp = 2'b00;
        s0_rlast = 1;
        s0_rvalid = 1;

        wait_count = 0;

        while ((m0_rvalid !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        #1;

        if (m0_rvalid === 1'b1 &&
            m0_rid == 4'h1 &&
            m0_rdata == 32'h12345678 &&
            m0_rresp == 2'b00 &&
            m0_rlast === 1'b1) begin

            $display("PASS: S0 response routed to M0");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: S0 response routing");

            $display("MASTER: valid=%b ready=%b id=%h data=%h",
                     m0_rvalid, m0_rready, m0_rid, m0_rdata);

            $display("SLAVE: valid=%b ready=%b id=%h data=%h",
                     s0_rvalid, s0_rready, s0_rid, s0_rdata);

            $display("R ROUTER OWNER: valid=%b owner=%b",
                     DUT.s0_read_active, DUT.U_R_ROUTER.s0_owner);

            fail_count = fail_count + 1;
        end

        // Now accept the response.
        @(negedge aclk);
        m0_rready = 1;

        @(posedge aclk);
        #1;

        @(negedge aclk);
        s0_rvalid = 0;
        s0_rlast = 0;
        m0_rready = 0;


        // =========================================
        // TEST 2: M1 -> SLAVE 1
        // =========================================

        $display("\nTEST 2: M1 -> SLAVE 1");

        @(negedge aclk);

        m1_arid = 4'h2;
        m1_araddr = 32'h00010040;
        m1_arlen = 0;
        m1_arvalid = 1;
        s1_arready = 1;

        #1;

        wait_count = 0;

        while ((m1_arready !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        if (m1_arready === 1'b1 &&
            s1_arvalid === 1'b1 &&
            s1_arready === 1'b1 &&
            s1_arid == 4'h2 &&
            s1_araddr == 32'h00010040 &&
            m1_ar_accept === 1'b1) begin

            $display("PASS: M1 address routed to S1");
            pass_count = pass_count + 1;

            @(posedge aclk);
            #1;
        end
        else begin
            $display("FAIL: M1 -> S1 address handshake");
            fail_count = fail_count + 1;
        end

       
        @(negedge aclk);
        m1_arvalid = 0;
        s1_arready = 0;

        // Hold M1 not-ready initially.
        m1_rready = 0;

        @(negedge aclk);
        s1_rid = 4'h2;
        s1_rdata = 32'hABCDEF12;
        s1_rresp = 2'b00;
        s1_rlast = 1;
        s1_rvalid = 1;

        wait_count = 0;

        while ((m1_rvalid !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        #1;

        if (m1_rvalid === 1'b1 &&
            m1_rid == 4'h2 &&
            m1_rdata == 32'hABCDEF12 &&
            m1_rresp == 2'b00 &&
            m1_rlast === 1'b1) begin

            $display("PASS: S1 response routed to M1");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: S1 response routing");

            $display("MASTER: valid=%b ready=%b id=%h data=%h",
                     m1_rvalid, m1_rready, m1_rid, m1_rdata);

            $display("SLAVE: valid=%b ready=%b id=%h data=%h",
                     s1_rvalid, s1_rready, s1_rid, s1_rdata);

            $display("R ROUTER OWNER: valid=%b owner=%b",
                     DUT.s1_read_active, DUT.U_R_ROUTER.s1_owner);

            fail_count = fail_count + 1;
        end

        // Accept response after checking it.
        @(negedge aclk);
        m1_rready = 1;

        @(posedge aclk);
        #1;

        @(negedge aclk);
        s1_rvalid = 0;
        s1_rlast = 0;
        m1_rready = 0;


        // =========================================
        // TEST 3: M0 UNMAPPED -> DECERR
        // =========================================

        $display("\nTEST 3: M0 UNMAPPED ADDRESS");

        @(negedge aclk);

        m0_arid = 4'h3;
        m0_araddr = 32'h00020000;
        m0_arlen = 0;
        m0_arvalid = 1;
        m0_rready = 1;

        #1;

        wait_count = 0;

        while ((m0_arready !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        if (m0_arready === 1'b1 &&
            m0_ar_accept === 1'b1) begin

            $display("PASS: M0 unmapped request accepted");
            pass_count = pass_count + 1;

            @(posedge aclk);
            #1;
        end
        else begin
            $display("FAIL: M0 unmapped request acceptance");
            fail_count = fail_count + 1;
        end

        @(negedge aclk);
        m0_arvalid = 0;

        wait_count = 0;

        while ((m0_rvalid !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            wait_count = wait_count + 1;
        end

        #1;

        if (m0_rvalid &&
            m0_rid == 4'h3 &&
            m0_rdata == 32'h00000000 &&
            m0_rresp == DECERR &&
            m0_rlast) begin

            $display("PASS: M0 received correct DECERR response");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: M0 DECERR response");
            fail_count = fail_count + 1;
        end

        @(posedge aclk);
        #1;

        @(negedge aclk);
        m0_rready = 0;

        // =========================================
        // TEST 4: M1 UNMAPPED -> DECERR
        // =========================================

        $display("\nTEST 4: M1 UNMAPPED ADDRESS");

        @(negedge aclk);

        m1_arid = 4'h4;
        m1_araddr = 32'h00020010;
        m1_arlen = 0;
        m1_arvalid = 1;
        m1_rready = 1;

        #1;

        wait_count = 0;

        while ((m1_arready !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        if (m1_arready === 1'b1 &&
            m1_ar_accept === 1'b1) begin

            $display("PASS: M1 unmapped request accepted");
            pass_count = pass_count + 1;

            @(posedge aclk);
            #1;
        end
        else begin
            $display("FAIL: M1 unmapped request acceptance");
            fail_count = fail_count + 1;
        end

        @(negedge aclk);
        m1_arvalid = 0;

        wait_count = 0;

        while ((m1_rvalid !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            wait_count = wait_count + 1;
        end

        #1;

        if (m1_rvalid &&
            m1_rid == 4'h4 &&
            m1_rdata == 32'h00000000 &&
            m1_rresp == DECERR &&
            m1_rlast) begin

            $display("PASS: M1 received correct DECERR response");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: M1 DECERR response");
            fail_count = fail_count + 1;
        end

        @(posedge aclk);
        #1;

        @(negedge aclk);
        m1_rready = 0;

        // =========================================
        // TEST 5: DECERR BACKPRESSURE
        // =========================================

        $display("\nTEST 5: DECERR BACKPRESSURE");

        @(negedge aclk);

        m0_arid = 4'h5;
        m0_araddr = 32'h00030000;
        m0_arlen = 1;
        m0_arvalid = 1;
        m0_rready = 0;

        #1;

        wait_count = 0;

        while ((m0_arready !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            #1;
            wait_count = wait_count + 1;
        end

        if (m0_arready === 1'b1 &&
            m0_ar_accept === 1'b1) begin

            $display("PASS: DECERR burst address accepted");
            pass_count = pass_count + 1;

            @(posedge aclk);
            #1;
        end
        else begin
            $display("FAIL: DECERR burst address acceptance");
            fail_count = fail_count + 1;
        end

        @(negedge aclk);
        m0_arvalid = 0;

        wait_count = 0;

        while ((m0_rvalid !== 1'b1) && (wait_count < 20)) begin
            @(negedge aclk);
            wait_count = wait_count + 1;
        end

        #1;

        // Two-beat burst: first beat must not be last.
        repeat (3) begin
            if (m0_rvalid &&
                m0_rid == 4'h5 &&
                m0_rresp == DECERR &&
                !m0_rlast) begin

                $display("PASS: DECERR response stable under backpressure");
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: DECERR backpressure stability");
                fail_count = fail_count + 1;
            end

            @(posedge aclk);
            #1;
        end

        // Accept the first response beat.
        @(negedge aclk);
        m0_rready = 1;

        @(posedge aclk);
        #1;

        // The final beat must now be presented.
        if (m0_rvalid &&
            m0_rlast &&
            m0_rresp == DECERR) begin

            $display("PASS: DECERR final beat generated correctly");
            pass_count = pass_count + 1;
        end
        else begin
            $display("FAIL: DECERR final beat");
            fail_count = fail_count + 1;
        end

        @(posedge aclk);
        #1;

        @(negedge aclk);
        m0_rready = 0;

        // =========================================
        // TEST SUMMARY
        // =========================================

        repeat (3) @(posedge aclk);

        $display("\n==============================================");
        $display(" READ PATH TEST SUMMARY");
        $display(" PASSED : %0d", pass_count);
        $display(" FAILED : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
            $display("ALL COMPLETED TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $finish;
    end

    // =================================================
    // SIMULATION WATCHDOG
    // =================================================

    initial begin
        #100000;
        $display("ERROR: Simulation timeout");
        $finish;
    end
   


   

endmodule
