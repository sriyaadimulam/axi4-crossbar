
`timescale 1ns / 1ps

module axi4_crossbar_ar_router #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input wire aclk,
    input wire aresetn,

    // Master 0 AR interface
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
    output reg m0_arready,

    // Master 1 AR interface
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
    output reg m1_arready,

    // Slave 0 AR interface
    output reg [ID_WIDTH-1:0] s0_arid,
    output reg [ADDR_WIDTH-1:0] s0_araddr,
    output reg [7:0] s0_arlen,
    output reg [2:0] s0_arsize,
    output reg [1:0] s0_arburst,
    output reg s0_arlock,
    output reg [3:0] s0_arcache,
    output reg [2:0] s0_arprot,
    output reg [3:0] s0_arqos,
    output reg [3:0] s0_arregion,
    output reg s0_arvalid,
    input wire s0_arready,

    // Slave 1 AR interface
    output reg [ID_WIDTH-1:0] s1_arid,
    output reg [ADDR_WIDTH-1:0] s1_araddr,
    output reg [7:0] s1_arlen,
    output reg [2:0] s1_arsize,
    output reg [1:0] s1_arburst,
    output reg s1_arlock,
    output reg [3:0] s1_arcache,
    output reg [2:0] s1_arprot,
    output reg [3:0] s1_arqos,
    output reg [3:0] s1_arregion,
    output reg s1_arvalid,
    input wire s1_arready,

    // Master outstanding-read availability
    input wire m0_read_available,
    input wire m1_read_available,

    // Arbitration bank connections
    output wire [1:0] s0_rd_req,
    input wire [1:0] s0_rd_grant,
    input wire s0_rd_enable,

    output wire [1:0] s1_rd_req,
    input wire [1:0] s1_rd_grant,
    input wire s1_rd_enable,

    output wire s0_rd_grant_accept,
    output wire s1_rd_grant_accept,

    // Unmapped address indications
    output wire m0_ar_unmapped,
    output wire m1_ar_unmapped
);

    wire m0_to_s0;
    wire m0_to_s1;
    wire m1_to_s0;
    wire m1_to_s1;

    // Address decoding
    assign m0_to_s0 =
        (m0_araddr >= 32'h00000000) &&
        (m0_araddr <= 32'h0000FFFF);

    assign m0_to_s1 =
        (m0_araddr >= 32'h00010000) &&
        (m0_araddr <= 32'h0001FFFF);

    assign m1_to_s0 =
        (m1_araddr >= 32'h00000000) &&
        (m1_araddr <= 32'h0000FFFF);

    assign m1_to_s1 =
        (m1_araddr >= 32'h00010000) &&
        (m1_araddr <= 32'h0001FFFF);

    // Flag unmapped requests.
    assign m0_ar_unmapped =
        m0_arvalid && !(m0_to_s0 || m0_to_s1);

    assign m1_ar_unmapped =
        m1_arvalid && !(m1_to_s0 || m1_to_s1);

    // Generate arbitration requests.
    assign s0_rd_req[0] =
        m0_arvalid && m0_read_available && m0_to_s0;

    assign s0_rd_req[1] =
        m1_arvalid && m1_read_available && m1_to_s0;

    assign s1_rd_req[0] =
        m0_arvalid && m0_read_available && m0_to_s1;

    assign s1_rd_req[1] =
        m1_arvalid && m1_read_available && m1_to_s1;

    // Address channel handshakes.
    assign s0_rd_grant_accept = s0_arvalid && s0_arready;
    assign s1_rd_grant_accept = s1_arvalid && s1_arready;

    // AR routing
    always @(*) begin

        // Default master READY values
        m0_arready = 1'b0;
        m1_arready = 1'b0;

        // Default slave 0 signals
        s0_arid     = 0;
        s0_araddr   = 0;
        s0_arlen    = 0;
        s0_arsize   = 0;
        s0_arburst  = 0;
        s0_arlock   = 0;
        s0_arcache  = 0;
        s0_arprot   = 0;
        s0_arqos    = 0;
        s0_arregion = 0;
        s0_arvalid  = 0;

        // Default slave 1 signals
        s1_arid     = 0;
        s1_araddr   = 0;
        s1_arlen    = 0;
        s1_arsize   = 0;
        s1_arburst  = 0;
        s1_arlock   = 0;
        s1_arcache  = 0;
        s1_arprot   = 0;
        s1_arqos    = 0;
        s1_arregion = 0;
        s1_arvalid  = 0;

        // Slave 0 selection
        if (s0_rd_enable) begin

            if (s0_rd_grant == 2'b01) begin
                s0_arid     = m0_arid;
                s0_araddr   = m0_araddr;
                s0_arlen    = m0_arlen;
                s0_arsize   = m0_arsize;
                s0_arburst  = m0_arburst;
                s0_arlock   = m0_arlock;
                s0_arcache  = m0_arcache;
                s0_arprot   = m0_arprot;
                s0_arqos    = m0_arqos;
                s0_arregion = m0_arregion;
                s0_arvalid  = m0_arvalid && m0_read_available &&
                              m0_to_s0;

                if (s0_arvalid)
                    m0_arready = s0_arready;
            end

            else if (s0_rd_grant == 2'b10) begin
                s0_arid     = m1_arid;
                s0_araddr   = m1_araddr;
                s0_arlen    = m1_arlen;
                s0_arsize   = m1_arsize;
                s0_arburst  = m1_arburst;
                s0_arlock   = m1_arlock;
                s0_arcache  = m1_arcache;
                s0_arprot   = m1_arprot;
                s0_arqos    = m1_arqos;
                s0_arregion = m1_arregion;
                s0_arvalid  = m1_arvalid && m1_read_available &&
                              m1_to_s0;

                if (s0_arvalid)
                    m1_arready = s0_arready;
            end
        end

        // Slave 1 selection
        if (s1_rd_enable) begin

            if (s1_rd_grant == 2'b01) begin
                s1_arid     = m0_arid;
                s1_araddr   = m0_araddr;
                s1_arlen    = m0_arlen;
                s1_arsize   = m0_arsize;
                s1_arburst  = m0_arburst;
                s1_arlock   = m0_arlock;
                s1_arcache  = m0_arcache;
                s1_arprot   = m0_arprot;
                s1_arqos    = m0_arqos;
                s1_arregion = m0_arregion;
                s1_arvalid  = m0_arvalid && m0_read_available &&
                              m0_to_s1;

                if (s1_arvalid)
                    m0_arready = s1_arready;
            end

            else if (s1_rd_grant == 2'b10) begin
                s1_arid     = m1_arid;
                s1_araddr   = m1_araddr;
                s1_arlen    = m1_arlen;
                s1_arsize   = m1_arsize;
                s1_arburst  = m1_arburst;
                s1_arlock   = m1_arlock;
                s1_arcache  = m1_arcache;
                s1_arprot   = m1_arprot;
                s1_arqos    = m1_arqos;
                s1_arregion = m1_arregion;
                s1_arvalid  = m1_arvalid && m1_read_available &&
                              m1_to_s1;

                if (s1_arvalid)
                    m1_arready = s1_arready;
            end
        end

    end

endmodule
