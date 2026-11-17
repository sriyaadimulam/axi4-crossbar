`timescale 1ns / 1ps

module axi4_demo_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter BURST_BEATS = 4
)(
    input wire aclk,
    input wire aresetn,
    input wire start,

    // 00 = Fixed priority
    // 01 = Round robin
    // 10 = Burst-aware age-based (not yet fully operational)
    input wire [1:0] arb_policy,

    output wire [31:0] m0_transaction_count,
    output wire [31:0] m1_transaction_count,

    output wire m0_error,
    output wire m1_error,
    output wire m0_active,
    output wire m1_active
);

    // =================================================
    // MASTER 0 AXI SIGNALS
    // =================================================

    wire [ID_WIDTH-1:0] m0_awid;
    wire [ADDR_WIDTH-1:0] m0_awaddr;
    wire [7:0] m0_awlen;
    wire [2:0] m0_awsize;
    wire [1:0] m0_awburst;
    wire m0_awvalid;
    wire m0_awready;

    wire [DATA_WIDTH-1:0] m0_wdata;
    wire [DATA_WIDTH/8-1:0] m0_wstrb;
    wire m0_wlast;
    wire m0_wvalid;
    wire m0_wready;

    wire [ID_WIDTH-1:0] m0_bid;
    wire [1:0] m0_bresp;
    wire m0_bvalid;
    wire m0_bready;

    wire [ID_WIDTH-1:0] m0_arid;
    wire [ADDR_WIDTH-1:0] m0_araddr;
    wire [7:0] m0_arlen;
    wire [2:0] m0_arsize;
    wire [1:0] m0_arburst;
    wire m0_arvalid;
    wire m0_arready;

    wire [ID_WIDTH-1:0] m0_rid;
    wire [DATA_WIDTH-1:0] m0_rdata;
    wire [1:0] m0_rresp;
    wire m0_rlast;
    wire m0_rvalid;
    wire m0_rready;


    // =================================================
    // MASTER 1 AXI SIGNALS
    // =================================================

    wire [ID_WIDTH-1:0] m1_awid;
    wire [ADDR_WIDTH-1:0] m1_awaddr;
    wire [7:0] m1_awlen;
    wire [2:0] m1_awsize;
    wire [1:0] m1_awburst;
    wire m1_awvalid;
    wire m1_awready;

    wire [DATA_WIDTH-1:0] m1_wdata;
    wire [DATA_WIDTH/8-1:0] m1_wstrb;
    wire m1_wlast;
    wire m1_wvalid;
    wire m1_wready;

    wire [ID_WIDTH-1:0] m1_bid;
    wire [1:0] m1_bresp;
    wire m1_bvalid;
    wire m1_bready;

    wire [ID_WIDTH-1:0] m1_arid;
    wire [ADDR_WIDTH-1:0] m1_araddr;
    wire [7:0] m1_arlen;
    wire [2:0] m1_arsize;
    wire [1:0] m1_arburst;
    wire m1_arvalid;
    wire m1_arready;

    wire [ID_WIDTH-1:0] m1_rid;
    wire [DATA_WIDTH-1:0] m1_rdata;
    wire [1:0] m1_rresp;
    wire m1_rlast;
    wire m1_rvalid;
    wire m1_rready;


    // =================================================
    // SLAVE 0 AXI SIGNALS
    // =================================================

    wire [ID_WIDTH-1:0] s0_awid;
    wire [ADDR_WIDTH-1:0] s0_awaddr;
    wire [7:0] s0_awlen;
    wire [2:0] s0_awsize;
    wire [1:0] s0_awburst;
    wire s0_awlock;
    wire [3:0] s0_awcache;
    wire [2:0] s0_awprot;
    wire [3:0] s0_awqos;
    wire [3:0] s0_awregion;
    wire s0_awvalid;
    wire s0_awready;

    wire [DATA_WIDTH-1:0] s0_wdata;
    wire [DATA_WIDTH/8-1:0] s0_wstrb;
    wire s0_wlast;
    wire s0_wvalid;
    wire s0_wready;

    wire [ID_WIDTH-1:0] s0_bid;
    wire [1:0] s0_bresp;
    wire s0_bvalid;
    wire s0_bready;

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
    wire s0_arready;

    wire [ID_WIDTH-1:0] s0_rid;
    wire [DATA_WIDTH-1:0] s0_rdata;
    wire [1:0] s0_rresp;
    wire s0_rlast;
    wire s0_rvalid;
    wire s0_rready;


    // =================================================
    // SLAVE 1 AXI SIGNALS
    // =================================================

    wire [ID_WIDTH-1:0] s1_awid;
    wire [ADDR_WIDTH-1:0] s1_awaddr;
    wire [7:0] s1_awlen;
    wire [2:0] s1_awsize;
    wire [1:0] s1_awburst;
    wire s1_awlock;
    wire [3:0] s1_awcache;
    wire [2:0] s1_awprot;
    wire [3:0] s1_awqos;
    wire [3:0] s1_awregion;
    wire s1_awvalid;
    wire s1_awready;

    wire [DATA_WIDTH-1:0] s1_wdata;
    wire [DATA_WIDTH/8-1:0] s1_wstrb;
    wire s1_wlast;
    wire s1_wvalid;
    wire s1_wready;

    wire [ID_WIDTH-1:0] s1_bid;
    wire [1:0] s1_bresp;
    wire s1_bvalid;
    wire s1_bready;

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
    wire s1_arready;

    wire [ID_WIDTH-1:0] s1_rid;
    wire [DATA_WIDTH-1:0] s1_rdata;
    wire [1:0] s1_rresp;
    wire s1_rlast;
    wire s1_rvalid;
    wire s1_rready;


    // =================================================
    // 1. AUTOMATIC MASTER 0
    // =================================================

    axi4_auto_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MASTER_ID(0),
        .BURST_BEATS(BURST_BEATS)
    ) U_MASTER0 (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(start),

        .m_awid(m0_awid),
        .m_awaddr(m0_awaddr),
        .m_awlen(m0_awlen),
        .m_awsize(m0_awsize),
        .m_awburst(m0_awburst),
        .m_awvalid(m0_awvalid),
        .m_awready(m0_awready),

        .m_wdata(m0_wdata),
        .m_wstrb(m0_wstrb),
        .m_wlast(m0_wlast),
        .m_wvalid(m0_wvalid),
        .m_wready(m0_wready),

        .m_bid(m0_bid),
        .m_bresp(m0_bresp),
        .m_bvalid(m0_bvalid),
        .m_bready(m0_bready),

        .m_arid(m0_arid),
        .m_araddr(m0_araddr),
        .m_arlen(m0_arlen),
        .m_arsize(m0_arsize),
        .m_arburst(m0_arburst),
        .m_arvalid(m0_arvalid),
        .m_arready(m0_arready),

        .m_rid(m0_rid),
        .m_rdata(m0_rdata),
        .m_rresp(m0_rresp),
        .m_rlast(m0_rlast),
        .m_rvalid(m0_rvalid),
        .m_rready(m0_rready),

        .transaction_count(m0_transaction_count),
        .error_flag(m0_error),
        .active(m0_active)
    );


    // =================================================
    // 2. AUTOMATIC MASTER 1
    // =================================================

    axi4_auto_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MASTER_ID(1),
        .BURST_BEATS(BURST_BEATS)
    ) U_MASTER1 (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(start),

        .m_awid(m1_awid),
        .m_awaddr(m1_awaddr),
        .m_awlen(m1_awlen),
        .m_awsize(m1_awsize),
        .m_awburst(m1_awburst),
        .m_awvalid(m1_awvalid),
        .m_awready(m1_awready),

        .m_wdata(m1_wdata),
        .m_wstrb(m1_wstrb),
        .m_wlast(m1_wlast),
        .m_wvalid(m1_wvalid),
        .m_wready(m1_wready),

        .m_bid(m1_bid),
        .m_bresp(m1_bresp),
        .m_bvalid(m1_bvalid),
        .m_bready(m1_bready),

        .m_arid(m1_arid),
        .m_araddr(m1_araddr),
        .m_arlen(m1_arlen),
        .m_arsize(m1_arsize),
        .m_arburst(m1_arburst),
        .m_arvalid(m1_arvalid),
        .m_arready(m1_arready),

        .m_rid(m1_rid),
        .m_rdata(m1_rdata),
        .m_rresp(m1_rresp),
        .m_rlast(m1_rlast),
        .m_rvalid(m1_rvalid),
        .m_rready(m1_rready),

        .transaction_count(m1_transaction_count),
        .error_flag(m1_error),
        .active(m1_active)
    );


    // =================================================
    // 3. AXI4 CROSSBAR
    // =================================================

    axi4_crossbar_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MAX_BURST_LEN(16)
    ) U_CROSSBAR (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        // MASTER 0 AW
        .m0_awid(m0_awid),
        .m0_awaddr(m0_awaddr),
        .m0_awlen(m0_awlen),
        .m0_awsize(m0_awsize),
        .m0_awburst(m0_awburst),
        .m0_awlock(1'b0),
        .m0_awcache(4'b0011),
        .m0_awprot(3'b000),
        .m0_awqos(4'b0000),
        .m0_awregion(4'b0000),
        .m0_awvalid(m0_awvalid),
        .m0_awready(m0_awready),

        // MASTER 0 W
        .m0_wdata(m0_wdata),
        .m0_wstrb(m0_wstrb),
        .m0_wlast(m0_wlast),
        .m0_wvalid(m0_wvalid),
        .m0_wready(m0_wready),

        // MASTER 0 B
        .m0_bid(m0_bid),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),

        // MASTER 0 AR
        .m0_arid(m0_arid),
        .m0_araddr(m0_araddr),
        .m0_arlen(m0_arlen),
        .m0_arsize(m0_arsize),
        .m0_arburst(m0_arburst),
        .m0_arlock(1'b0),
        .m0_arcache(4'b0011),
        .m0_arprot(3'b000),
        .m0_arqos(4'b0000),
        .m0_arregion(4'b0000),
        .m0_arvalid(m0_arvalid),
        .m0_arready(m0_arready),

        // MASTER 0 R
        .m0_rid(m0_rid),
        .m0_rdata(m0_rdata),
        .m0_rresp(m0_rresp),
        .m0_rlast(m0_rlast),
        .m0_rvalid(m0_rvalid),
        .m0_rready(m0_rready),

        // MASTER 1 AW
        .m1_awid(m1_awid),
        .m1_awaddr(m1_awaddr),
        .m1_awlen(m1_awlen),
        .m1_awsize(m1_awsize),
        .m1_awburst(m1_awburst),
        .m1_awlock(1'b0),
        .m1_awcache(4'b0011),
        .m1_awprot(3'b000),
        .m1_awqos(4'b0000),
        .m1_awregion(4'b0000),
        .m1_awvalid(m1_awvalid),
        .m1_awready(m1_awready),

        // MASTER 1 W
        .m1_wdata(m1_wdata),
        .m1_wstrb(m1_wstrb),
        .m1_wlast(m1_wlast),
        .m1_wvalid(m1_wvalid),
        .m1_wready(m1_wready),

        // MASTER 1 B
        .m1_bid(m1_bid),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),

        // MASTER 1 AR
        .m1_arid(m1_arid),
        .m1_araddr(m1_araddr),
        .m1_arlen(m1_arlen),
        .m1_arsize(m1_arsize),
        .m1_arburst(m1_arburst),
        .m1_arlock(1'b0),
        .m1_arcache(4'b0011),
        .m1_arprot(3'b000),
        .m1_arqos(4'b0000),
        .m1_arregion(4'b0000),
        .m1_arvalid(m1_arvalid),
        .m1_arready(m1_arready),

        // MASTER 1 R
        .m1_rid(m1_rid),
        .m1_rdata(m1_rdata),
        .m1_rresp(m1_rresp),
        .m1_rlast(m1_rlast),
        .m1_rvalid(m1_rvalid),
        .m1_rready(m1_rready),

        // SLAVE 0 AW
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

        // SLAVE 0 W
        .s0_wdata(s0_wdata),
        .s0_wstrb(s0_wstrb),
        .s0_wlast(s0_wlast),
        .s0_wvalid(s0_wvalid),
        .s0_wready(s0_wready),

        // SLAVE 0 B
        .s0_bid(s0_bid),
        .s0_bresp(s0_bresp),
        .s0_bvalid(s0_bvalid),
        .s0_bready(s0_bready),

        // SLAVE 0 AR
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

        // SLAVE 0 R
        .s0_rid(s0_rid),
        .s0_rdata(s0_rdata),
        .s0_rresp(s0_rresp),
        .s0_rlast(s0_rlast),
        .s0_rvalid(s0_rvalid),
        .s0_rready(s0_rready),

        // SLAVE 1 AW
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

        // SLAVE 1 W
        .s1_wdata(s1_wdata),
        .s1_wstrb(s1_wstrb),
        .s1_wlast(s1_wlast),
        .s1_wvalid(s1_wvalid),
        .s1_wready(s1_wready),

        // SLAVE 1 B
        .s1_bid(s1_bid),
        .s1_bresp(s1_bresp),
        .s1_bvalid(s1_bvalid),
        .s1_bready(s1_bready),

        // SLAVE 1 AR
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

        // SLAVE 1 R
        .s1_rid(s1_rid),
        .s1_rdata(s1_rdata),
        .s1_rresp(s1_rresp),
        .s1_rlast(s1_rlast),
        .s1_rvalid(s1_rvalid),
        .s1_rready(s1_rready)
    );


    // =================================================
    // 4. SLAVE 0 MEMORY
    // =================================================

    axi4_simple_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .BASE_ADDR(32'h00000000),
        .MEM_WORDS(16384)
    ) U_MEMORY0 (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_awid(s0_awid),
        .s_awaddr(s0_awaddr),
        .s_awlen(s0_awlen),
        .s_awsize(s0_awsize),
        .s_awburst(s0_awburst),
        .s_awvalid(s0_awvalid),
        .s_awready(s0_awready),

        .s_wdata(s0_wdata),
        .s_wstrb(s0_wstrb),
        .s_wlast(s0_wlast),
        .s_wvalid(s0_wvalid),
        .s_wready(s0_wready),

        .s_bid(s0_bid),
        .s_bresp(s0_bresp),
        .s_bvalid(s0_bvalid),
        .s_bready(s0_bready),

        .s_arid(s0_arid),
        .s_araddr(s0_araddr),
        .s_arlen(s0_arlen),
        .s_arsize(s0_arsize),
        .s_arburst(s0_arburst),
        .s_arvalid(s0_arvalid),
        .s_arready(s0_arready),

        .s_rid(s0_rid),
        .s_rdata(s0_rdata),
        .s_rresp(s0_rresp),
        .s_rlast(s0_rlast),
        .s_rvalid(s0_rvalid),
        .s_rready(s0_rready)
    );


    // =================================================
    // 5. SLAVE 1 MEMORY
    // =================================================

    axi4_simple_memory #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .BASE_ADDR(32'h00010000),
        .MEM_WORDS(16384)
    ) U_MEMORY1 (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_awid(s1_awid),
        .s_awaddr(s1_awaddr),
        .s_awlen(s1_awlen),
        .s_awsize(s1_awsize),
        .s_awburst(s1_awburst),
        .s_awvalid(s1_awvalid),
        .s_awready(s1_awready),

        .s_wdata(s1_wdata),
        .s_wstrb(s1_wstrb),
        .s_wlast(s1_wlast),
        .s_wvalid(s1_wvalid),
        .s_wready(s1_wready),

        .s_bid(s1_bid),
        .s_bresp(s1_bresp),
        .s_bvalid(s1_bvalid),
        .s_bready(s1_bready),

        .s_arid(s1_arid),
        .s_araddr(s1_araddr),
        .s_arlen(s1_arlen),
        .s_arsize(s1_arsize),
        .s_arburst(s1_arburst),
        .s_arvalid(s1_arvalid),
        .s_arready(s1_arready),

        .s_rid(s1_rid),
        .s_rdata(s1_rdata),
        .s_rresp(s1_rresp),
        .s_rlast(s1_rlast),
        .s_rvalid(s1_rvalid),
        .s_rready(s1_rready)
    );

endmodule
