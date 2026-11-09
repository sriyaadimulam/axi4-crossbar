
`timescale 1ns / 1ps

module axi4_crossbar_top #(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter ID_WIDTH      = 4,
    parameter MAX_BURST_LEN = 16,
    parameter AGE_WIDTH     = 32,
    parameter SERVICE_WIDTH = 32,
    parameter ARB_WEIGHT    = 2
)(
    // =====================================================
    // CLOCK AND RESET
    // =====================================================
    input wire aclk,
    input wire aresetn,

    // Arbitration policy:
    // 00 = Fixed priority
    // 01 = Round robin
    // 10 = Burst-aware age-based
    input wire [1:0] arb_policy,


    // =====================================================
    // MASTER 0 INTERFACE
    // =====================================================

    // Write Address (AW)
    input  wire [ID_WIDTH-1:0]   m0_awid,
    input  wire [ADDR_WIDTH-1:0] m0_awaddr,
    input  wire [7:0]            m0_awlen,
    input  wire [2:0]            m0_awsize,
    input  wire [1:0]            m0_awburst,
    input  wire                  m0_awlock,
    input  wire [3:0]            m0_awcache,
    input  wire [2:0]            m0_awprot,
    input  wire [3:0]            m0_awqos,
    input  wire [3:0]            m0_awregion,
    input  wire                  m0_awvalid,
    output wire                  m0_awready,

    // Write Data (W)
    input  wire [DATA_WIDTH-1:0] m0_wdata,
    input  wire [DATA_WIDTH/8-1:0] m0_wstrb,
    input  wire                  m0_wlast,
    input  wire                  m0_wvalid,
    output wire                  m0_wready,

    // Write Response (B)
    output wire [ID_WIDTH-1:0]   m0_bid,
    output wire [1:0]            m0_bresp,
    output wire                  m0_bvalid,
    input  wire                  m0_bready,

    // Read Address (AR)
    input  wire [ID_WIDTH-1:0]   m0_arid,
    input  wire [ADDR_WIDTH-1:0] m0_araddr,
    input  wire [7:0]            m0_arlen,
    input  wire [2:0]            m0_arsize,
    input  wire [1:0]            m0_arburst,
    input  wire                  m0_arlock,
    input  wire [3:0]            m0_arcache,
    input  wire [2:0]            m0_arprot,
    input  wire [3:0]            m0_arqos,
    input  wire [3:0]            m0_arregion,
    input  wire                  m0_arvalid,
    output wire                  m0_arready,

    // Read Data (R)
    output wire [ID_WIDTH-1:0]   m0_rid,
    output wire [DATA_WIDTH-1:0] m0_rdata,
    output wire [1:0]            m0_rresp,
    output wire                  m0_rlast,
    output wire                  m0_rvalid,
    input  wire                  m0_rready,


    // =====================================================
    // MASTER 1 INTERFACE
    // =====================================================

    // Write Address (AW)
    input  wire [ID_WIDTH-1:0]   m1_awid,
    input  wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire [7:0]            m1_awlen,
    input  wire [2:0]            m1_awsize,
    input  wire [1:0]            m1_awburst,
    input  wire                  m1_awlock,
    input  wire [3:0]            m1_awcache,
    input  wire [2:0]            m1_awprot,
    input  wire [3:0]            m1_awqos,
    input  wire [3:0]            m1_awregion,
    input  wire                  m1_awvalid,
    output wire                  m1_awready,

    // Write Data (W)
    input  wire [DATA_WIDTH-1:0] m1_wdata,
    input  wire [DATA_WIDTH/8-1:0] m1_wstrb,
    input  wire                  m1_wlast,
    input  wire                  m1_wvalid,
    output wire                  m1_wready,

    // Write Response (B)
    output wire [ID_WIDTH-1:0]   m1_bid,
    output wire [1:0]            m1_bresp,
    output wire                  m1_bvalid,
    input  wire                  m1_bready,

    // Read Address (AR)
    input  wire [ID_WIDTH-1:0]   m1_arid,
    input  wire [ADDR_WIDTH-1:0] m1_araddr,
    input  wire [7:0]            m1_arlen,
    input  wire [2:0]            m1_arsize,
    input  wire [1:0]            m1_arburst,
    input  wire                  m1_arlock,
    input  wire [3:0]            m1_arcache,
    input  wire [2:0]            m1_arprot,
    input  wire [3:0]            m1_arqos,
    input  wire [3:0]            m1_arregion,
    input  wire                  m1_arvalid,
    output wire                  m1_arready,

    // Read Data (R)
    output wire [ID_WIDTH-1:0]   m1_rid,
    output wire [DATA_WIDTH-1:0] m1_rdata,
    output wire [1:0]            m1_rresp,
    output wire                  m1_rlast,
    output wire                  m1_rvalid,
    input  wire                  m1_rready,


    // =====================================================
    // SLAVE 0 INTERFACE
    // =====================================================

    // Write Address (AW)
    output wire [ID_WIDTH-1:0]   s0_awid,
    output wire [ADDR_WIDTH-1:0] s0_awaddr,
    output wire [7:0]            s0_awlen,
    output wire [2:0]            s0_awsize,
    output wire [1:0]            s0_awburst,
    output wire                  s0_awlock,
    output wire [3:0]            s0_awcache,
    output wire [2:0]            s0_awprot,
    output wire [3:0]            s0_awqos,
    output wire [3:0]            s0_awregion,
    output wire                  s0_awvalid,
    input  wire                  s0_awready,

    // Write Data (W)
    output wire [DATA_WIDTH-1:0] s0_wdata,
    output wire [DATA_WIDTH/8-1:0] s0_wstrb,
    output wire                  s0_wlast,
    output wire                  s0_wvalid,
    input  wire                  s0_wready,

    // Write Response (B)
    input  wire [ID_WIDTH-1:0]   s0_bid,
    input  wire [1:0]            s0_bresp,
    input  wire                  s0_bvalid,
    output wire                  s0_bready,

    // Read Address (AR)
    output wire [ID_WIDTH-1:0]   s0_arid,
    output wire [ADDR_WIDTH-1:0] s0_araddr,
    output wire [7:0]            s0_arlen,
    output wire [2:0]            s0_arsize,
    output wire [1:0]            s0_arburst,
    output wire                  s0_arlock,
    output wire [3:0]            s0_arcache,
    output wire [2:0]            s0_arprot,
    output wire [3:0]            s0_arqos,
    output wire [3:0]            s0_arregion,
    output wire                  s0_arvalid,
    input  wire                  s0_arready,

    // Read Data (R)
    input  wire [ID_WIDTH-1:0]   s0_rid,
    input  wire [DATA_WIDTH-1:0] s0_rdata,
    input  wire [1:0]            s0_rresp,
    input  wire                  s0_rlast,
    input  wire                  s0_rvalid,
    output wire                  s0_rready,


    // =====================================================
    // SLAVE 1 INTERFACE
    // =====================================================

    // Write Address (AW)
    output wire [ID_WIDTH-1:0]   s1_awid,
    output wire [ADDR_WIDTH-1:0] s1_awaddr,
    output wire [7:0]            s1_awlen,
    output wire [2:0]            s1_awsize,
    output wire [1:0]            s1_awburst,
    output wire                  s1_awlock,
    output wire [3:0]            s1_awcache,
    output wire [2:0]            s1_awprot,
    output wire [3:0]            s1_awqos,
    output wire [3:0]            s1_awregion,
    output wire                  s1_awvalid,
    input  wire                  s1_awready,

    // Write Data (W)
    output wire [DATA_WIDTH-1:0] s1_wdata,
    output wire [DATA_WIDTH/8-1:0] s1_wstrb,
    output wire                  s1_wlast,
    output wire                  s1_wvalid,
    input  wire                  s1_wready,

    // Write Response (B)
    input  wire [ID_WIDTH-1:0]   s1_bid,
    input  wire [1:0]            s1_bresp,
    input  wire                  s1_bvalid,
    output wire                  s1_bready,

    // Read Address (AR)
    output wire [ID_WIDTH-1:0]   s1_arid,
    output wire [ADDR_WIDTH-1:0] s1_araddr,
    output wire [7:0]            s1_arlen,
    output wire [2:0]            s1_arsize,
    output wire [1:0]            s1_arburst,
    output wire                  s1_arlock,
    output wire [3:0]            s1_arcache,
    output wire [2:0]            s1_arprot,
    output wire [3:0]            s1_arqos,
    output wire [3:0]            s1_arregion,
    output wire                  s1_arvalid,
    input  wire                  s1_arready,

    // Read Data (R)
    input  wire [ID_WIDTH-1:0]   s1_rid,
    input  wire [DATA_WIDTH-1:0] s1_rdata,
    input  wire [1:0]            s1_rresp,
    input  wire                  s1_rlast,
    input  wire                  s1_rvalid,
    output wire                  s1_rready

);

    // =====================================================
    // INTERNAL IMPLEMENTATION
    // =====================================================

    // -----------------------------------------------------
    // 1. MASTER TRACKER SIGNALS
    // -----------------------------------------------------

    wire m0_read_available;
    wire m0_write_available;
    wire m1_read_available;
    wire m1_write_available;

    wire m0_ar_accept;
    wire m1_ar_accept;
    wire m0_read_complete;
    wire m1_read_complete;

    wire m0_aw_accept;
    wire m1_aw_accept;
    wire m0_write_complete;
    wire m1_write_complete;

    // -----------------------------------------------------
    // 2. DECERR HANDLER SIGNALS
    // -----------------------------------------------------

    // DECERR READ ADDRESS
    wire [ID_WIDTH-1:0] decerr_arid;
    wire [7:0] decerr_arlen;
    wire decerr_arvalid;
    wire decerr_arready;

    // DECERR READ RESPONSE
    wire [ID_WIDTH-1:0] decerr_rid;
    wire [DATA_WIDTH-1:0] decerr_rdata;
    wire [1:0] decerr_rresp;
    wire decerr_rlast;
    wire decerr_rvalid;
    wire decerr_rready;

    // DECERR WRITE ADDRESS
    wire [ID_WIDTH-1:0] decerr_awid;
    wire [7:0] decerr_awlen;
    wire decerr_awvalid;
    wire decerr_awready;

    // DECERR WRITE DATA
    wire [DATA_WIDTH-1:0] decerr_wdata;
    wire [DATA_WIDTH/8-1:0] decerr_wstrb;
    wire decerr_wlast;
    wire decerr_wvalid;
    wire decerr_wready;

    // DECERR WRITE RESPONSE
    wire [ID_WIDTH-1:0] decerr_bid;
    wire [1:0] decerr_bresp;
    wire decerr_bvalid;
    wire decerr_bready;

    // -----------------------------------------------------
    // 3. SLAVE READ OWNERSHIP STATUS
    // -----------------------------------------------------

    wire s0_read_active;
    wire s1_read_active;

    // -----------------------------------------------------
    // 4. SLAVE WRITE SLOT STATUS
    // -----------------------------------------------------

    wire s0_write_slot_available;
    wire s1_write_slot_available;

    // -----------------------------------------------------
    // 5. UNMAPPED WRITE ADDRESS INDICATIONS
    // -----------------------------------------------------

    wire m0_aw_unmapped;
    wire m1_aw_unmapped;

    // -----------------------------------------------------
    // 6. BURST-AGE SERVICE INPUTS
    //
    // Temporarily tied low.
    // These will be connected to the service-history
    // logic in a subsequent integration milestone.
    // -----------------------------------------------------

    wire s0_rd_service_valid;
    wire s0_rd_service_master;
    wire s0_rd_epoch_clear;

    wire s1_rd_service_valid;
    wire s1_rd_service_master;
    wire s1_rd_epoch_clear;

    wire s0_wr_service_valid;
    wire s0_wr_service_master;
    wire s0_wr_epoch_clear;

    wire s1_wr_service_valid;
    wire s1_wr_service_master;
    wire s1_wr_epoch_clear;

    assign s0_rd_service_valid  = 1'b0;
    assign s0_rd_service_master = 1'b0;
    assign s0_rd_epoch_clear    = 1'b0;

    assign s1_rd_service_valid  = 1'b0;
    assign s1_rd_service_master = 1'b0;
    assign s1_rd_epoch_clear    = 1'b0;

    assign s0_wr_service_valid  = 1'b0;
    assign s0_wr_service_master = 1'b0;
    assign s0_wr_epoch_clear    = 1'b0;

    assign s1_wr_service_valid  = 1'b0;
    assign s1_wr_service_master = 1'b0;
    assign s1_wr_epoch_clear    = 1'b0;


    // =====================================================
    // 7. SHARED MASTER TRACKER
    // =====================================================

    master_tracker U_MASTER_TRACKER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Master 0 read events
        .m0_ar_accept(m0_ar_accept),
        .m0_read_complete(m0_read_complete),

        // Master 0 write events
        .m0_aw_accept(m0_aw_accept),
        .m0_write_complete(m0_write_complete),

        // Master 1 read events
        .m1_ar_accept(m1_ar_accept),
        .m1_read_complete(m1_read_complete),

        // Master 1 write events
        .m1_aw_accept(m1_aw_accept),
        .m1_write_complete(m1_write_complete),

        // Master status
        .m0_read_busy(),
        .m0_write_busy(),
        .m1_read_busy(),
        .m1_write_busy(),

        // Availability
        .m0_read_available(m0_read_available),
        .m0_write_available(m0_write_available),

        .m1_read_available(m1_read_available),
        .m1_write_available(m1_write_available)
    );


    // =====================================================
    // 8. SHARED DECERR HANDLER
    // =====================================================

    axi4_crossbar_decerr_handler #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) U_DECERR_HANDLER (

        .aclk(aclk),
        .aresetn(aresetn),

        // ---------------------------------------------
        // Read address
        // ---------------------------------------------

        .m_arid(decerr_arid),
        .m_arlen(decerr_arlen),
        .m_arvalid(decerr_arvalid),
        .m_arready(decerr_arready),

        // ---------------------------------------------
        // Read response
        // ---------------------------------------------

        .m_rid(decerr_rid),
        .m_rdata(decerr_rdata),
        .m_rresp(decerr_rresp),
        .m_rlast(decerr_rlast),
        .m_rvalid(decerr_rvalid),
        .m_rready(decerr_rready),

        // ---------------------------------------------
        // Write address
        // ---------------------------------------------

        .m_awid(decerr_awid),
        .m_awlen(decerr_awlen),
        .m_awvalid(decerr_awvalid),
        .m_awready(decerr_awready),

        // ---------------------------------------------
        // Write data
        // ---------------------------------------------

        .m_wdata(decerr_wdata),
        .m_wstrb(decerr_wstrb),
        .m_wlast(decerr_wlast),
        .m_wvalid(decerr_wvalid),
        .m_wready(decerr_wready),

        // ---------------------------------------------
        // Write response
        // ---------------------------------------------

        .m_bid(decerr_bid),
        .m_bresp(decerr_bresp),
        .m_bvalid(decerr_bvalid),
        .m_bready(decerr_bready)
    );


    // =====================================================
    // 9. AXI4 READ PATH
    // =====================================================

    axi4_crossbar_read_path #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .AGE_WIDTH(AGE_WIDTH),
        .SERVICE_WIDTH(SERVICE_WIDTH)
    ) U_READ_PATH (

        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        // ---------------------------------------------
        // Master 0 AR
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Master 1 AR
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Slave 0 AR
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Slave 1 AR
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Slave 0 R
        // ---------------------------------------------

        .s0_rid(s0_rid),
        .s0_rdata(s0_rdata),
        .s0_rresp(s0_rresp),
        .s0_rlast(s0_rlast),
        .s0_rvalid(s0_rvalid),
        .s0_rready(s0_rready),

        // ---------------------------------------------
        // Slave 1 R
        // ---------------------------------------------

        .s1_rid(s1_rid),
        .s1_rdata(s1_rdata),
        .s1_rresp(s1_rresp),
        .s1_rlast(s1_rlast),
        .s1_rvalid(s1_rvalid),
        .s1_rready(s1_rready),

        // ---------------------------------------------
        // Master 0 R
        // ---------------------------------------------

        .m0_rid(m0_rid),
        .m0_rdata(m0_rdata),
        .m0_rresp(m0_rresp),
        .m0_rlast(m0_rlast),
        .m0_rvalid(m0_rvalid),
        .m0_rready(m0_rready),

        // ---------------------------------------------
        // Master 1 R
        // ---------------------------------------------

        .m1_rid(m1_rid),
        .m1_rdata(m1_rdata),
        .m1_rresp(m1_rresp),
        .m1_rlast(m1_rlast),
        .m1_rvalid(m1_rvalid),
        .m1_rready(m1_rready),

        // ---------------------------------------------
        // Shared tracker
        // ---------------------------------------------

        .m0_read_available(m0_read_available),
        .m1_read_available(m1_read_available),

        .m0_ar_accept(m0_ar_accept),
        .m1_ar_accept(m1_ar_accept),

        .m0_read_complete(m0_read_complete),
        .m1_read_complete(m1_read_complete),

        // ---------------------------------------------
        // Burst-age service signals
        // ---------------------------------------------

        .s0_rd_service_valid(s0_rd_service_valid),
        .s0_rd_service_master(s0_rd_service_master),
        .s0_rd_epoch_clear(s0_rd_epoch_clear),

        .s1_rd_service_valid(s1_rd_service_valid),
        .s1_rd_service_master(s1_rd_service_master),
        .s1_rd_epoch_clear(s1_rd_epoch_clear),

        // ---------------------------------------------
        // Slave ownership
        // ---------------------------------------------

        .s0_read_active(s0_read_active),
        .s1_read_active(s1_read_active),

        // ---------------------------------------------
        // DECERR read interface
        // ---------------------------------------------

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


    // =====================================================
    // 10. AXI4 WRITE PATH
    // =====================================================

    axi4_crossbar_write_path #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) U_WRITE_PATH (

        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        // ---------------------------------------------
        // Shared tracker availability
        // ---------------------------------------------

        .m0_write_available(m0_write_available),
        .m1_write_available(m1_write_available),

        // ---------------------------------------------
        // Master 0 AW
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Master 1 AW
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Master 0 W
        // ---------------------------------------------

        .m0_wdata(m0_wdata),
        .m0_wstrb(m0_wstrb),
        .m0_wlast(m0_wlast),
        .m0_wvalid(m0_wvalid),
        .m0_wready(m0_wready),

        // ---------------------------------------------
        // Master 1 W
        // ---------------------------------------------

        .m1_wdata(m1_wdata),
        .m1_wstrb(m1_wstrb),
        .m1_wlast(m1_wlast),
        .m1_wvalid(m1_wvalid),
        .m1_wready(m1_wready),

        // ---------------------------------------------
        // Slave 0 W
        // ---------------------------------------------

        .s0_wdata(s0_wdata),
        .s0_wstrb(s0_wstrb),
        .s0_wlast(s0_wlast),
        .s0_wvalid(s0_wvalid),
        .s0_wready(s0_wready),

        // ---------------------------------------------
        // Slave 1 W
        // ---------------------------------------------

        .s1_wdata(s1_wdata),
        .s1_wstrb(s1_wstrb),
        .s1_wlast(s1_wlast),
        .s1_wvalid(s1_wvalid),
        .s1_wready(s1_wready),

        // ---------------------------------------------
        // Slave 0 AW
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Slave 1 AW
        // ---------------------------------------------

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

        // ---------------------------------------------
        // Master 0 B
        // ---------------------------------------------

        .m0_bid(m0_bid),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),

        // ---------------------------------------------
        // Master 1 B
        // ---------------------------------------------

        .m1_bid(m1_bid),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),

        // ---------------------------------------------
        // Slave 0 B
        // ---------------------------------------------

        .s0_bid(s0_bid),
        .s0_bresp(s0_bresp),
        .s0_bvalid(s0_bvalid),
        .s0_bready(s0_bready),

        // ---------------------------------------------
        // Slave 1 B
        // ---------------------------------------------

        .s1_bid(s1_bid),
        .s1_bresp(s1_bresp),
        .s1_bvalid(s1_bvalid),
        .s1_bready(s1_bready),

        // ---------------------------------------------
        // Burst-age service signals
        // ---------------------------------------------

        .s0_wr_service_valid(s0_wr_service_valid),
        .s0_wr_service_master(s0_wr_service_master),
        .s0_wr_epoch_clear(s0_wr_epoch_clear),

        .s1_wr_service_valid(s1_wr_service_valid),
        .s1_wr_service_master(s1_wr_service_master),
        .s1_wr_epoch_clear(s1_wr_epoch_clear),

        // ---------------------------------------------
        // Shared tracker events
        // ---------------------------------------------

        .m0_aw_accept(m0_aw_accept),
        .m1_aw_accept(m1_aw_accept),

        .m0_write_complete(m0_write_complete),
        .m1_write_complete(m1_write_complete),

        // ---------------------------------------------
        // Slave write-slot status
        // ---------------------------------------------

        .s0_write_slot_available(s0_write_slot_available),
        .s1_write_slot_available(s1_write_slot_available),

        // ---------------------------------------------
        // Unmapped indications
        // ---------------------------------------------

        .m0_aw_unmapped(m0_aw_unmapped),
        .m1_aw_unmapped(m1_aw_unmapped),

        // ---------------------------------------------
        // DECERR write interface
        // ---------------------------------------------

        .decerr_awid(decerr_awid),
        .decerr_awlen(decerr_awlen),
        .decerr_awvalid(decerr_awvalid),
        .decerr_awready(decerr_awready),

        .decerr_wdata(decerr_wdata),
        .decerr_wstrb(decerr_wstrb),
        .decerr_wlast(decerr_wlast),
        .decerr_wvalid(decerr_wvalid),
        .decerr_wready(decerr_wready),

        .decerr_bid(decerr_bid),
        .decerr_bresp(decerr_bresp),
        .decerr_bvalid(decerr_bvalid),
        .decerr_bready(decerr_bready)
    );
    

endmodule
