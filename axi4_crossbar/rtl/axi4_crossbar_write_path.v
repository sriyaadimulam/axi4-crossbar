
`timescale 1ns / 1ps

module axi4_crossbar_write_path #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
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
    // Master 0 W interface
    // ------------------------------------------------
    input wire [DATA_WIDTH-1:0] m0_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m0_wstrb,
    input wire m0_wlast,
    input wire m0_wvalid,
    output wire m0_wready,

    // ------------------------------------------------
    // Master 1 W interface
    // ------------------------------------------------
    input wire [DATA_WIDTH-1:0] m1_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m1_wstrb,
    input wire m1_wlast,
    input wire m1_wvalid,
    output wire m1_wready,

    // ------------------------------------------------
    // Slave 0 W interface
    // ------------------------------------------------
    output wire [DATA_WIDTH-1:0] s0_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s0_wstrb,
    output wire s0_wlast,
    output wire s0_wvalid,
    input wire s0_wready,

    // ------------------------------------------------
    // Slave 1 W interface
    // ------------------------------------------------
    output wire [DATA_WIDTH-1:0] s1_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s1_wstrb,
    output wire s1_wlast,
    output wire s1_wvalid,
    input wire s1_wready,

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
    output wire m1_aw_unmapped,

    // ------------------------------------------------
    // DECERR WRITE HANDLER INTERFACE
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] decerr_awid,
    output wire [7:0] decerr_awlen,
    output wire decerr_awvalid,
    input wire decerr_awready,

    output wire [DATA_WIDTH-1:0] decerr_wdata,
    output wire [(DATA_WIDTH/8)-1:0] decerr_wstrb,
    output wire decerr_wlast,
    output wire decerr_wvalid,
    input wire decerr_wready,

    input wire [ID_WIDTH-1:0] decerr_bid,
    input wire [1:0] decerr_bresp,
    input wire decerr_bvalid,
    output wire decerr_bready
);

    // =================================================
    // INTERNAL ARBITRATION SIGNALS
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
    // DECERR INTERNAL SIGNALS
    // =================================================

    wire mapped_m0_awready;
    wire mapped_m1_awready;

    wire mapped_m0_wready;
    wire mapped_m1_wready;

    wire [ID_WIDTH-1:0] normal_m0_bid;
    wire [1:0] normal_m0_bresp;
    wire normal_m0_bvalid;
    wire normal_m0_bready;

    wire [ID_WIDTH-1:0] normal_m1_bid;
    wire [1:0] normal_m1_bresp;
    wire normal_m1_bvalid;
    wire normal_m1_bready;

    wire [1:0] decerr_wr_req;
    wire [1:0] decerr_wr_grant;

    wire decerr_wr_grant_accept;
    wire decerr_wr_enable;
    wire decerr_wr_aw_accept;

    reg decerr_wr_owner_valid;
    reg decerr_wr_owner;

    // =================================================
    // SLAVE WRITE-SLOT AVAILABILITY
    // =================================================

    assign s0_wr_enable = s0_write_slot_available;
    assign s1_wr_enable = s1_write_slot_available;

    // =================================================
    // MASTER TRACKER EVENT GENERATION
    // =================================================

    assign m0_aw_accept = m0_awvalid && m0_awready;
    assign m1_aw_accept = m1_awvalid && m1_awready;

    assign m0_write_complete = m0_bvalid && m0_bready;
    assign m1_write_complete = m1_bvalid && m1_bready;

    // =================================================
    // WRITE ARBITRATION BANK
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
    // AW ADDRESS ROUTER
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
        .m0_awready(mapped_m0_awready),

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
        .m1_awready(mapped_m1_awready),

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
    // DECERR WRITE ARBITRATION
    // =================================================

    assign decerr_wr_req[0] =
        m0_aw_unmapped && m0_write_available;

    assign decerr_wr_req[1] =
        m1_aw_unmapped && m1_write_available;

    // Do not depend on READY to assert VALID.
    // The locked arbiter holds the selected grant
    // until the handler accepts the AW transaction.
    assign decerr_wr_enable = !decerr_wr_owner_valid;

    arbitration_policy_unit_locked U_DECERR_WRITE_ARBITER (

        .aclk(aclk),
        .aresetn(aresetn),

        .arb_policy(arb_policy),

        .req(decerr_wr_req),
        .arb_enable(decerr_wr_enable),

        .grant_accept(decerr_wr_grant_accept),

        // DECERR requests do not update normal
        // memory-burst age service history.
        .service_valid(1'b0),
        .service_master(1'b0),
        .epoch_clear(1'b0),

        .grant(decerr_wr_grant)
    );

    assign decerr_awid =
        decerr_wr_grant[0] ? m0_awid :
        decerr_wr_grant[1] ? m1_awid :
        {ID_WIDTH{1'b0}};

    assign decerr_awlen =
        decerr_wr_grant[0] ? m0_awlen :
        decerr_wr_grant[1] ? m1_awlen :
        8'd0;

    assign decerr_awvalid = |decerr_wr_grant;

    assign decerr_wr_grant_accept =
        decerr_awvalid && decerr_awready;

    assign decerr_wr_aw_accept = decerr_wr_grant_accept;

    // Combine mapped and unmapped AWREADY.
    assign m0_awready =
        mapped_m0_awready ||
        (decerr_wr_grant[0] && decerr_awready);

    assign m1_awready =
        mapped_m1_awready ||
        (decerr_wr_grant[1] && decerr_awready);

    // =================================================
    // DECERR WRITE OWNERSHIP TRACKING
    // =================================================

    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            decerr_wr_owner_valid <= 1'b0;
            decerr_wr_owner       <= 1'b0;
        end

        else begin

            if (decerr_wr_aw_accept) begin
                decerr_wr_owner_valid <= 1'b1;
                decerr_wr_owner       <= decerr_wr_grant[1];
            end

            else if (decerr_bvalid && decerr_bready) begin
                decerr_wr_owner_valid <= 1'b0;
            end

        end
    end

    // =================================================
    // B RESPONSE ROUTER AND OWNERSHIP TRACKING
    // =================================================

    axi4_crossbar_b_router #(
        .ID_WIDTH(ID_WIDTH)
    ) U_B_ROUTER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Master 0 normal B
        .m0_bid(normal_m0_bid),
        .m0_bresp(normal_m0_bresp),
        .m0_bvalid(normal_m0_bvalid),
        .m0_bready(normal_m0_bready),

        // Master 1 normal B
        .m1_bid(normal_m1_bid),
        .m1_bresp(normal_m1_bresp),
        .m1_bvalid(normal_m1_bvalid),
        .m1_bready(normal_m1_bready),

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

    // =================================================
    // NORMAL / DECERR WRITE RESPONSE MULTIPLEXER
    // =================================================

    // Master 0 response
    assign m0_bid =
        (decerr_wr_owner_valid && !decerr_wr_owner)
        ? decerr_bid : normal_m0_bid;

    assign m0_bresp =
        (decerr_wr_owner_valid && !decerr_wr_owner)
        ? decerr_bresp : normal_m0_bresp;

    assign m0_bvalid =
        (decerr_wr_owner_valid && !decerr_wr_owner)
        ? decerr_bvalid : normal_m0_bvalid;

    // Master 1 response
    assign m1_bid =
        (decerr_wr_owner_valid && decerr_wr_owner)
        ? decerr_bid : normal_m1_bid;

    assign m1_bresp =
        (decerr_wr_owner_valid && decerr_wr_owner)
        ? decerr_bresp : normal_m1_bresp;

    assign m1_bvalid =
        (decerr_wr_owner_valid && decerr_wr_owner)
        ? decerr_bvalid : normal_m1_bvalid;

    // Normal B router READY
    assign normal_m0_bready =
        m0_bready &&
        !(decerr_wr_owner_valid && !decerr_wr_owner);

    assign normal_m1_bready =
        m1_bready &&
        !(decerr_wr_owner_valid && decerr_wr_owner);

    // DECERR handler READY
    assign decerr_bready =
        decerr_wr_owner_valid &&
        (decerr_wr_owner ? m1_bready : m0_bready);

    // =================================================
    // W DATA ROUTER AND OWNERSHIP TRACKING
    // =================================================

    axi4_crossbar_w_router #(
        .DATA_WIDTH(DATA_WIDTH)
    ) U_W_ROUTER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Master 0 W
        .m0_wdata(m0_wdata),
        .m0_wstrb(m0_wstrb),
        .m0_wlast(m0_wlast),
        .m0_wvalid(m0_wvalid),
        .m0_wready(mapped_m0_wready),

        // Master 1 W
        .m1_wdata(m1_wdata),
        .m1_wstrb(m1_wstrb),
        .m1_wlast(m1_wlast),
        .m1_wvalid(m1_wvalid),
        .m1_wready(mapped_m1_wready),

        // Slave 0 W
        .s0_wdata(s0_wdata),
        .s0_wstrb(s0_wstrb),
        .s0_wlast(s0_wlast),
        .s0_wvalid(s0_wvalid),
        .s0_wready(s0_wready),

        // Slave 1 W
        .s1_wdata(s1_wdata),
        .s1_wstrb(s1_wstrb),
        .s1_wlast(s1_wlast),
        .s1_wvalid(s1_wvalid),
        .s1_wready(s1_wready),

        // AW handshake and ownership
        .s0_aw_accept(s0_wr_grant_accept),
        .s0_aw_owner(s0_aw_owner),

        .s1_aw_accept(s1_wr_grant_accept),
        .s1_aw_owner(s1_aw_owner)
    );

    // =================================================
    // DECERR WRITE DATA ROUTING
    // =================================================

    assign decerr_wdata =
        decerr_wr_owner ? m1_wdata : m0_wdata;

    assign decerr_wstrb =
        decerr_wr_owner ? m1_wstrb : m0_wstrb;

    assign decerr_wlast =
        decerr_wr_owner ? m1_wlast : m0_wlast;

    assign decerr_wvalid =
        decerr_wr_owner_valid &&
        (decerr_wr_owner ? m1_wvalid : m0_wvalid);

    // Return WREADY only to the selected destination.
    assign m0_wready =
        (decerr_wr_owner_valid && !decerr_wr_owner)
        ? decerr_wready : mapped_m0_wready;

    assign m1_wready =
        (decerr_wr_owner_valid && decerr_wr_owner)
        ? decerr_wready : mapped_m1_wready;

endmodule
