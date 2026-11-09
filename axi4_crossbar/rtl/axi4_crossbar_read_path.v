
`timescale 1ns / 1ps

module axi4_crossbar_read_path #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter AGE_WIDTH  = 32,
    parameter SERVICE_WIDTH = 32
)(
    input wire aclk,
    input wire aresetn,

    // Arbitration policy
    // 00: Fixed priority
    // 01: Round robin
    // 10: Burst-aware age-based
    // 11: Reserved
    input wire [1:0] arb_policy,

    // --------------------------------------------
    // Master 0 AR interface
    // --------------------------------------------
    input wire [ID_WIDTH-1:0] m0_arid,
    input wire [ADDR_WIDTH-1:0] m0_araddr,
    input wire [7:0] m0_arlen,
    input wire [2:0] m0_arsize,
    input wire [1:0] m0_arburst,
    input wire m0_arlock,
    input wire [3:0] m0_arcache,
    input wire [2:0] m0_arprot,
    input wire [3:0] m0_arqos,
    input wire [3:0] m0_arregion,
    input wire m0_arvalid,
    output wire m0_arready,

    // --------------------------------------------
    // Master 1 AR interface
    // --------------------------------------------
    input wire [ID_WIDTH-1:0] m1_arid,
    input wire [ADDR_WIDTH-1:0] m1_araddr,
    input wire [7:0] m1_arlen,
    input wire [2:0] m1_arsize,
    input wire [1:0] m1_arburst,
    input wire m1_arlock,
    input wire [3:0] m1_arcache,
    input wire [2:0] m1_arprot,
    input wire [3:0] m1_arqos,
    input wire [3:0] m1_arregion,
    input wire m1_arvalid,
    output wire m1_arready,

    // --------------------------------------------
    // Slave 0 AR interface
    // --------------------------------------------
    output wire [ID_WIDTH-1:0] s0_arid,
    output wire [ADDR_WIDTH-1:0] s0_araddr,
    output wire [7:0] s0_arlen,
    output wire [2:0] s0_arsize,
    output wire [1:0] s0_arburst,
    output wire s0_arlock,
    output wire [3:0] s0_arcache,
    output wire [2:0] s0_arprot,
    output wire [3:0] s0_arqos,
    output wire [3:0] s0_arregion,
    output wire s0_arvalid,
    input wire s0_arready,

    // --------------------------------------------
    // Slave 1 AR interface
    // --------------------------------------------
    output wire [ID_WIDTH-1:0] s1_arid,
    output wire [ADDR_WIDTH-1:0] s1_araddr,
    output wire [7:0] s1_arlen,
    output wire [2:0] s1_arsize,
    output wire [1:0] s1_arburst,
    output wire s1_arlock,
    output wire [3:0] s1_arcache,
    output wire [2:0] s1_arprot,
    output wire [3:0] s1_arqos,
    output wire [3:0] s1_arregion,
    output wire s1_arvalid,
    input wire s1_arready,

    // --------------------------------------------
    // Slave 0 R interface
    // --------------------------------------------
    input wire [ID_WIDTH-1:0] s0_rid,
    input wire [DATA_WIDTH-1:0] s0_rdata,
    input wire [1:0] s0_rresp,
    input wire s0_rlast,
    input wire s0_rvalid,
    output wire s0_rready,

    // --------------------------------------------
    // Slave 1 R interface
    // --------------------------------------------
    input wire [ID_WIDTH-1:0] s1_rid,
    input wire [DATA_WIDTH-1:0] s1_rdata,
    input wire [1:0] s1_rresp,
    input wire s1_rlast,
    input wire s1_rvalid,
    output wire s1_rready,

    // --------------------------------------------
    // Master 0 R interface
    // --------------------------------------------
    output wire [ID_WIDTH-1:0] m0_rid,
    output wire [DATA_WIDTH-1:0] m0_rdata,
    output wire [1:0] m0_rresp,
    output wire m0_rlast,
    output wire m0_rvalid,
    input wire m0_rready,

    // --------------------------------------------
    // Master 1 R interface
    // --------------------------------------------
    output wire [ID_WIDTH-1:0] m1_rid,
    output wire [DATA_WIDTH-1:0] m1_rdata,
    output wire [1:0] m1_rresp,
    output wire m1_rlast,
    output wire m1_rvalid,
    input wire m1_rready,

    // --------------------------------------------
    // Master transaction tracking interface
    // Shared with the write path
    // --------------------------------------------
    input wire m0_read_available,
    input wire m1_read_available,

    output wire m0_ar_accept,
    output wire m1_ar_accept,

    output wire m0_read_complete,
    output wire m1_read_complete,

    // --------------------------------------------
    // Burst-age arbitration service information
    // --------------------------------------------
    input wire s0_rd_service_valid,
    input wire s0_rd_service_master,
    input wire s0_rd_epoch_clear,

    input wire s1_rd_service_valid,
    input wire s1_rd_service_master,
    input wire s1_rd_epoch_clear,

    // --------------------------------------------
    // Slave ownership status
    // --------------------------------------------
    output wire s0_read_active,
    output wire s1_read_active,

    // --------------------------------------------
    // Shared DECERR handler read address interface
    // --------------------------------------------
    output wire [ID_WIDTH-1:0] decerr_arid,
    output wire [7:0] decerr_arlen,
    output wire decerr_arvalid,
    input wire decerr_arready,

    // --------------------------------------------
    // Shared DECERR handler read response interface
    // --------------------------------------------
    input wire [ID_WIDTH-1:0] decerr_rid,
    input wire [DATA_WIDTH-1:0] decerr_rdata,
    input wire [1:0] decerr_rresp,
    input wire decerr_rlast,
    input wire decerr_rvalid,
    output wire decerr_rready
);

    // ============================================
    // INTERNAL SIGNAL DECLARATIONS
    // ============================================

    // Address decoder outputs
    wire m0_s0_sel;
    wire m0_s1_sel;
    wire m0_decode_error;

    wire m1_s0_sel;
    wire m1_s1_sel;
    wire m1_decode_error;

    // Normal read arbitration
    wire [1:0] s0_rd_req;
    wire [1:0] s1_rd_req;

    wire [1:0] s0_rd_grant;
    wire [1:0] s1_rd_grant;

    wire s0_rd_grant_accept;
    wire s1_rd_grant_accept;

    wire s0_rd_enable;
    wire s1_rd_enable;

    // Mapped ARREADY signals
    wire mapped_m0_arready;
    wire mapped_m1_arready;

    // Normal R response signals
    wire [ID_WIDTH-1:0] normal_m0_rid;
    wire [DATA_WIDTH-1:0] normal_m0_rdata;
    wire [1:0] normal_m0_rresp;
    wire normal_m0_rlast;
    wire normal_m0_rvalid;
    wire normal_m0_rready;

    wire [ID_WIDTH-1:0] normal_m1_rid;
    wire [DATA_WIDTH-1:0] normal_m1_rdata;
    wire [1:0] normal_m1_rresp;
    wire normal_m1_rlast;
    wire normal_m1_rvalid;
    wire normal_m1_rready;

    // Slave AR ownership capture
    wire s0_ar_accept;
    wire s1_ar_accept;
    wire s0_ar_owner;
    wire s1_ar_owner;

    // DECERR read arbitration
    wire [1:0] decerr_rd_req;
    wire [1:0] decerr_rd_grant;
    wire decerr_rd_enable;
    wire decerr_rd_grant_accept;

    // DECERR response ownership
    reg decerr_owner_valid;
    reg decerr_owner;


    // ============================================
    // ADDRESS DECODING
    // ============================================

    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_M0_ADDRESS_DECODER (
        .addr(m0_araddr),
        .s0_sel(m0_s0_sel),
        .s1_sel(m0_s1_sel),
        .decode_error(m0_decode_error)
    );

    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) U_M1_ADDRESS_DECODER (
        .addr(m1_araddr),
        .s0_sel(m1_s0_sel),
        .s1_sel(m1_s1_sel),
        .decode_error(m1_decode_error)
    );


    // ============================================
    // NORMAL READ ARBITRATION REQUEST GENERATION
    // ============================================

    // Request bit 0 = Master 0
    // Request bit 1 = Master 1

    assign s0_rd_req[0] =
        m0_arvalid && m0_read_available && m0_s0_sel;

    assign s0_rd_req[1] =
        m1_arvalid && m1_read_available && m1_s0_sel;

    assign s1_rd_req[0] =
        m0_arvalid && m0_read_available && m0_s1_sel;

    assign s1_rd_req[1] =
        m1_arvalid && m1_read_available && m1_s1_sel;

    // A slave can accept a new read address only
    // when it has no active read transaction.

    assign s0_rd_enable = ~s0_read_active;
    assign s1_rd_enable = ~s1_read_active;


    // ============================================
    // NORMAL READ ARBITRATION BANK
    // ============================================

    axi4_crossbar_read_arbiter_bank U_READ_ARBITER_BANK (

        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        .s0_rd_req(s0_rd_req),
        .s0_rd_enable(s0_rd_enable),
        .s0_rd_grant_accept(s0_rd_grant_accept),
        .s0_rd_service_valid(s0_rd_service_valid),
        .s0_rd_service_master(s0_rd_service_master),
        .s0_rd_epoch_clear(s0_rd_epoch_clear),
        .s0_rd_grant(s0_rd_grant),

        .s1_rd_req(s1_rd_req),
        .s1_rd_enable(s1_rd_enable),
        .s1_rd_grant_accept(s1_rd_grant_accept),
        .s1_rd_service_valid(s1_rd_service_valid),
        .s1_rd_service_master(s1_rd_service_master),
        .s1_rd_epoch_clear(s1_rd_epoch_clear),
        .s1_rd_grant(s1_rd_grant)
    );


    // ============================================
    // UNMAPPED READ REQUEST ARBITRATION
    // ============================================

    assign decerr_rd_req[0] =
        m0_arvalid && m0_read_available && m0_decode_error;

    assign decerr_rd_req[1] =
        m1_arvalid && m1_read_available && m1_decode_error;

    // Only one DECERR read may be outstanding.
    assign decerr_rd_enable = !decerr_owner_valid;

    arbitration_policy_unit_locked U_DECERR_READ_ARBITER (

        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        .req(decerr_rd_req),
        .arb_enable(decerr_rd_enable),

        .grant_accept(decerr_rd_grant_accept),

        // DECERR requests do not update memory-burst
        // age-based service history.
        .service_valid(1'b0),
        .service_master(1'b0),
        .epoch_clear(1'b0),

        .grant(decerr_rd_grant)
    );

    // Send the selected master's ID and burst length
    // to the shared DECERR handler.

    assign decerr_arvalid = |decerr_rd_grant;

    assign decerr_arid =
        decerr_rd_grant[0] ? m0_arid :
        decerr_rd_grant[1] ? m1_arid :
        {ID_WIDTH{1'b0}};

    assign decerr_arlen =
        decerr_rd_grant[0] ? m0_arlen :
        decerr_rd_grant[1] ? m1_arlen :
        8'd0;

    // The handler accepts the request when both
    // VALID and READY are asserted.

    assign decerr_rd_grant_accept =
        decerr_arvalid && decerr_arready;


    // ============================================
    // DECERR RESPONSE OWNERSHIP
    // ============================================

    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin
            decerr_owner_valid <= 1'b0;
            decerr_owner       <= 1'b0;
        end

        else begin

            // Capture the selected master when the
            // DECERR handler accepts its AR request.
            if (decerr_rd_grant_accept) begin
                decerr_owner_valid <= 1'b1;
                decerr_owner       <= decerr_rd_grant[1];
            end

            // Release ownership after the final
            // DECERR response beat is accepted.
            else if (
                decerr_owner_valid &&
                decerr_rvalid &&
                decerr_rready &&
                decerr_rlast
            ) begin
                decerr_owner_valid <= 1'b0;
            end

        end
    end


    // ============================================
    // READ ADDRESS ROUTER
    // ============================================

    axi4_crossbar_ar_router #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) U_AR_ROUTER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Master 0 AR
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
        .m0_arready(mapped_m0_arready),

        // Master 1 AR
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
        .m1_arready(mapped_m1_arready),

        // Slave 0 AR
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

        // Slave 1 AR
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

        // Master availability
        .m0_read_available(m0_read_available),
        .m1_read_available(m1_read_available),

        // Arbitration connections
        .s0_rd_req(),
        .s0_rd_grant(s0_rd_grant),
        .s0_rd_enable(s0_rd_enable),

        .s1_rd_req(),
        .s1_rd_grant(s1_rd_grant),
        .s1_rd_enable(s1_rd_enable),

        .s0_rd_grant_accept(s0_rd_grant_accept),
        .s1_rd_grant_accept(s1_rd_grant_accept),

        // Unmapped indicators are handled separately
        // by the DECERR arbitration logic.
        .m0_ar_unmapped(),
        .m1_ar_unmapped()
    );


    // ============================================
    // MASTER ARREADY MULTIPLEXER
    // ============================================

    // Mapped requests use the normal AR router.
    // Unmapped requests use the DECERR handler.

    assign m0_arready =
        m0_decode_error
        ? (decerr_rd_grant[0] && decerr_arready)
        : mapped_m0_arready;

    assign m1_arready =
        m1_decode_error
        ? (decerr_rd_grant[1] && decerr_arready)
        : mapped_m1_arready;


    // ============================================
    // READ RESPONSE OWNERSHIP AND ROUTING
    // ============================================

    // Accepted slave AR transactions
    assign s0_ar_accept = s0_arvalid && s0_arready;
    assign s1_ar_accept = s1_arvalid && s1_arready;

    // Grant bit 0 = Master 0
    // Grant bit 1 = Master 1
    assign s0_ar_owner = s0_rd_grant[1];
    assign s1_ar_owner = s1_rd_grant[1];


    // ============================================
    // NORMAL READ RESPONSE ROUTER
    // ============================================

    axi4_crossbar_r_router #(
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) U_R_ROUTER (

        .aclk(aclk),
        .aresetn(aresetn),

        // Accepted AR transactions
        .s0_ar_accept(s0_ar_accept),
        .s0_ar_owner(s0_ar_owner),

        .s1_ar_accept(s1_ar_accept),
        .s1_ar_owner(s1_ar_owner),

        // Slave 0 R
        .s0_rid(s0_rid),
        .s0_rdata(s0_rdata),
        .s0_rresp(s0_rresp),
        .s0_rlast(s0_rlast),
        .s0_rvalid(s0_rvalid),
        .s0_rready(s0_rready),

        // Slave 1 R
        .s1_rid(s1_rid),
        .s1_rdata(s1_rdata),
        .s1_rresp(s1_rresp),
        .s1_rlast(s1_rlast),
        .s1_rvalid(s1_rvalid),
        .s1_rready(s1_rready),

        // Master 0 normal R response
        .m0_rid(normal_m0_rid),
        .m0_rdata(normal_m0_rdata),
        .m0_rresp(normal_m0_rresp),
        .m0_rlast(normal_m0_rlast),
        .m0_rvalid(normal_m0_rvalid),
        .m0_rready(normal_m0_rready),

        // Master 1 normal R response
        .m1_rid(normal_m1_rid),
        .m1_rdata(normal_m1_rdata),
        .m1_rresp(normal_m1_rresp),
        .m1_rlast(normal_m1_rlast),
        .m1_rvalid(normal_m1_rvalid),
        .m1_rready(normal_m1_rready),

        // Slave ownership status
        .s0_owner_valid(s0_read_active),
        .s1_owner_valid(s1_read_active),

        .s0_owner(),
        .s1_owner()
    );


    // ============================================
    // NORMAL / DECERR READ RESPONSE MULTIPLEXER
    // ============================================

    // --------------------------------------------
    // Master 0 response
    // --------------------------------------------

    assign m0_rid =
        (decerr_owner_valid && !decerr_owner)
        ? decerr_rid : normal_m0_rid;

    assign m0_rdata =
        (decerr_owner_valid && !decerr_owner)
        ? decerr_rdata : normal_m0_rdata;

    assign m0_rresp =
        (decerr_owner_valid && !decerr_owner)
        ? decerr_rresp : normal_m0_rresp;

    assign m0_rlast =
        (decerr_owner_valid && !decerr_owner)
        ? decerr_rlast : normal_m0_rlast;

    assign m0_rvalid =
        (decerr_owner_valid && !decerr_owner)
        ? decerr_rvalid : normal_m0_rvalid;


    // --------------------------------------------
    // Master 1 response
    // --------------------------------------------

    assign m1_rid =
        (decerr_owner_valid && decerr_owner)
        ? decerr_rid : normal_m1_rid;

    assign m1_rdata =
        (decerr_owner_valid && decerr_owner)
        ? decerr_rdata : normal_m1_rdata;

    assign m1_rresp =
        (decerr_owner_valid && decerr_owner)
        ? decerr_rresp : normal_m1_rresp;

    assign m1_rlast =
        (decerr_owner_valid && decerr_owner)
        ? decerr_rlast : normal_m1_rlast;

    assign m1_rvalid =
        (decerr_owner_valid && decerr_owner)
        ? decerr_rvalid : normal_m1_rvalid;


    // --------------------------------------------
    // READY routing
    // --------------------------------------------

    // Suppress normal response READY for the master
    // currently receiving a DECERR response.

    assign normal_m0_rready =
        m0_rready && !(decerr_owner_valid && !decerr_owner);

    assign normal_m1_rready =
        m1_rready && !(decerr_owner_valid && decerr_owner);

    // Route the selected master's READY to the
    // shared DECERR handler.

    assign decerr_rready =
        decerr_owner_valid &&
        (decerr_owner ? m1_rready : m0_rready);


    // ============================================
    // MASTER READ TRANSACTION TRACKING EVENTS
    // ============================================

    // A read transaction starts when the master
    // ARVALID and ARREADY handshake occurs.

    assign m0_ar_accept = m0_arvalid && m0_arready;
    assign m1_ar_accept = m1_arvalid && m1_arready;

    // A read transaction completes when the master
    // accepts the final R response beat.

    assign m0_read_complete =
        m0_rvalid && m0_rready && m0_rlast;

    assign m1_read_complete =
        m1_rvalid && m1_rready && m1_rlast;

endmodule
