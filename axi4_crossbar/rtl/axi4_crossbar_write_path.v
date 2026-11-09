
`timescale 1ns / 1ps

module axi4_crossbar_write_path #(
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input wire aclk,
    input wire aresetn,

    // Arbitration policy
    input wire [1:0] arb_policy,

    // Master write availability from shared master_tracker
    input wire m0_write_available,
    input wire m1_write_available,

    // ------------------------------------------------
    // Master 0 AW interface
    // ------------------------------------------------
    input wire [ID_WIDTH-1:0] m0_awid,
    input wire [ADDR_WIDTH-1:0] m0_awaddr,
    input wire [7:0] m0_awlen,
    input wire [2:0] m0_awsize,
    input wire [1:0] m0_awburst,
    input wire m0_awlock,
    input wire [3:0] m0_awcache,
    input wire [2:0] m0_awprot,
    input wire [3:0] m0_awqos,
    input wire [3:0] m0_awregion,
    input wire m0_awvalid,
    output wire m0_awready,

    // ------------------------------------------------
    // Master 1 AW interface
    // ------------------------------------------------
    input wire [ID_WIDTH-1:0] m1_awid,
    input wire [ADDR_WIDTH-1:0] m1_awaddr,
    input wire [7:0] m1_awlen,
    input wire [2:0] m1_awsize,
    input wire [1:0] m1_awburst,
    input wire m1_awlock,
    input wire [3:0] m1_awcache,
    input wire [2:0] m1_awprot,
    input wire [3:0] m1_awqos,
    input wire [3:0] m1_awregion,
    input wire m1_awvalid,
    output wire m1_awready,

    // ------------------------------------------------
    // Slave 0 AW interface
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] s0_awid,
    output wire [ADDR_WIDTH-1:0] s0_awaddr,
    output wire [7:0] s0_awlen,
    output wire [2:0] s0_awsize,
    output wire [1:0] s0_awburst,
    output wire s0_awlock,
    output wire [3:0] s0_awcache,
    output wire [2:0] s0_awprot,
    output wire [3:0] s0_awqos,
    output wire [3:0] s0_awregion,
    output wire s0_awvalid,
    input wire s0_awready,

    // ------------------------------------------------
    // Slave 1 AW interface
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] s1_awid,
    output wire [ADDR_WIDTH-1:0] s1_awaddr,
    output wire [7:0] s1_awlen,
    output wire [2:0] s1_awsize,
    output wire [1:0] s1_awburst,
    output wire s1_awlock,
    output wire [3:0] s1_awcache,
    output wire [2:0] s1_awprot,
    output wire [3:0] s1_awqos,
    output wire [3:0] s1_awregion,
    output wire s1_awvalid,
    input wire s1_awready,

    // ------------------------------------------------
    // Master 0 B interface
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] m0_bid,
    output wire [1:0] m0_bresp,
    output wire m0_bvalid,
    input wire m0_bready,

    // ------------------------------------------------
    // Master 1 B interface
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] m1_bid,
    output wire [1:0] m1_bresp,
    output wire m1_bvalid,
    input wire m1_bready,

    // ------------------------------------------------
    // Slave 0 B interface
    // ------------------------------------------------
    input wire [ID_WIDTH-1:0] s0_bid,
    input wire [1:0] s0_bresp,
    input wire s0_bvalid,
    output wire s0_bready,

    // ------------------------------------------------
    // Slave 1 B interface
    // ------------------------------------------------
    input wire [ID_WIDTH-1:0] s1_bid,
    input wire [1:0] s1_bresp,
    input wire s1_bvalid,
    output wire s1_bready,

    // ------------------------------------------------
    // Burst-aware age arbitration service inputs
    // ------------------------------------------------
    input wire s0_wr_service_valid,
    input wire s0_wr_service_master,
    input wire s0_wr_epoch_clear,

    input wire s1_wr_service_valid,
    input wire s1_wr_service_master,
    input wire s1_wr_epoch_clear,

    // ------------------------------------------------
    // Master tracker event outputs
    // ------------------------------------------------
    output wire m0_aw_accept,
    output wire m1_aw_accept,

    output wire m0_write_complete,
    output wire m1_write_complete,

    // ------------------------------------------------
    // Status outputs
    // ------------------------------------------------
    output wire s0_write_slot_available,
    output wire s1_write_slot_available,

    output wire m0_aw_unmapped,
    output wire m1_aw_unmapped
);

    // =================================================
    // Internal arbitration signals
    // =================================================

    wire [1:0] s0_wr_req;
    wire [1:0] s1_wr_req;

    wire [1:0] s0_wr_grant;
    wire [1:0] s1_wr_grant;

    wire s0_wr_grant_accept;
    wire s1_wr_grant_accept;

    wire s0_aw_owner;
    wire s1_aw_owner;

    wire s0_wr_enable;
    wire s1_wr_enable;

    // =================================================
    // Slave write-slot availability
    // =================================================

    assign s0_wr_enable = s0_write_slot_available;
    assign s1_wr_enable = s1_write_slot_available;

    // =================================================
    // Master tracker event generation
    // =================================================

    assign m0_aw_accept = m0_awvalid && m0_awready;
    assign m1_aw_accept = m1_awvalid && m1_awready;

    assign m0_write_complete = m0_bvalid && m0_bready;
    assign m1_write_complete = m1_bvalid && m1_bready;

    // =================================================
    // Write arbitration bank
    // =================================================

    axi4_crossbar_write_arbiter_bank U_WRITE_ARBITER_BANK (

        .aclk(aclk),
        .aresetn(aresetn),

        .arb_policy(arb_policy),

        .s0_wr_req(s0_wr_req),
        .s0_wr_enable(s0_wr_enable),
        .s0_wr_grant_accept(s0_wr_grant_accept),

        .s0_wr_service_valid(s0_wr_service_valid),
        .s0_wr_service_master(s0_wr_service_master),
        .s0_wr_epoch_clear(s0_wr_epoch_clear),

        .s0_wr_grant(s0_wr_grant),

        .s1_wr_req(s1_wr_req),
        .s1_wr_enable(s1_wr_enable),
        .s1_wr_grant_accept(s1_wr_grant_accept),

        .s1_wr_service_valid(s1_wr_service_valid),
        .s1_wr_service_master(s1_wr_service_master),
        .s1_wr_epoch_clear(s1_wr_epoch_clear),

        .s1_wr_grant(s1_wr_grant)
    );

    // =================================================
    // AW address router
    // =================================================

    axi4_crossbar_aw_router #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) U_AW_ROUTER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Master 0 AW
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

        // Master 1 AW
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

        // Slave 0 AW
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

        // Slave 1 AW
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

        // Master availability
        .m0_write_available(m0_write_available),
        .m1_write_available(m1_write_available),

        // Arbitration
        .s0_wr_req(s0_wr_req),
        .s0_wr_grant(s0_wr_grant),
        .s0_wr_enable(s0_wr_enable),

        .s1_wr_req(s1_wr_req),
        .s1_wr_grant(s1_wr_grant),
        .s1_wr_enable(s1_wr_enable),

        .s0_wr_grant_accept(s0_wr_grant_accept),
        .s1_wr_grant_accept(s1_wr_grant_accept),

        // Ownership
        .s0_aw_owner(s0_aw_owner),
        .s1_aw_owner(s1_aw_owner),

        // Unmapped indications
        .m0_aw_unmapped(m0_aw_unmapped),
        .m1_aw_unmapped(m1_aw_unmapped)
    );

    // =================================================
    // B response router and ownership tracking
    // =================================================

    axi4_crossbar_b_router #(
        .ID_WIDTH(ID_WIDTH)
    ) U_B_ROUTER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Master 0 B
        .m0_bid(m0_bid),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),

        // Master 1 B
        .m1_bid(m1_bid),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),

        // Slave 0 B
        .s0_bid(s0_bid),
        .s0_bresp(s0_bresp),
        .s0_bvalid(s0_bvalid),
        .s0_bready(s0_bready),

        // Slave 1 B
        .s1_bid(s1_bid),
        .s1_bresp(s1_bresp),
        .s1_bvalid(s1_bvalid),
        .s1_bready(s1_bready),

        // AW ownership
        .s0_aw_accept(s0_wr_grant_accept),
        .s0_aw_owner(s0_aw_owner),

        .s1_aw_accept(s1_wr_grant_accept),
        .s1_aw_owner(s1_aw_owner),

        // Write-slot availability
        .s0_write_slot_available(s0_write_slot_available),
        .s1_write_slot_available(s1_write_slot_available)
    );

endmodule
