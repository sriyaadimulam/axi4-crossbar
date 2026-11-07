
`timescale 1ns / 1ps

module axi4_crossbar_aw_router #(
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input wire aclk,
    input wire aresetn,

    // Master 0 AW interface
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
    output reg m0_awready,

    // Master 1 AW interface
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
    output reg m1_awready,

    // Slave 0 AW interface
    output reg [ID_WIDTH-1:0] s0_awid,
    output reg [ADDR_WIDTH-1:0] s0_awaddr,
    output reg [7:0] s0_awlen,
    output reg [2:0] s0_awsize,
    output reg [1:0] s0_awburst,
    output reg s0_awlock,
    output reg [3:0] s0_awcache,
    output reg [2:0] s0_awprot,
    output reg [3:0] s0_awqos,
    output reg [3:0] s0_awregion,
    output reg s0_awvalid,
    input wire s0_awready,

    // Slave 1 AW interface
    output reg [ID_WIDTH-1:0] s1_awid,
    output reg [ADDR_WIDTH-1:0] s1_awaddr,
    output reg [7:0] s1_awlen,
    output reg [2:0] s1_awsize,
    output reg [1:0] s1_awburst,
    output reg s1_awlock,
    output reg [3:0] s1_awcache,
    output reg [2:0] s1_awprot,
    output reg [3:0] s1_awqos,
    output reg [3:0] s1_awregion,
    output reg s1_awvalid,
    input wire s1_awready,

    // Master outstanding-write availability
    input wire m0_write_available,
    input wire m1_write_available,

    // Arbitration bank connections
    output wire [1:0] s0_wr_req,
    input wire [1:0] s0_wr_grant,
    input wire s0_wr_enable,

    output wire [1:0] s1_wr_req,
    input wire [1:0] s1_wr_grant,
    input wire s1_wr_enable,

    output wire s0_wr_grant_accept,
    output wire s1_wr_grant_accept,

    // Accepted transaction owner
    output wire s0_aw_owner,
    output wire s1_aw_owner,

    // Unmapped address indications
    output wire m0_aw_unmapped,
    output wire m1_aw_unmapped
);

    wire m0_to_s0;
    wire m0_to_s1;
    wire m1_to_s0;
    wire m1_to_s1;

    // --------------------------------
    // Address decoding
    // --------------------------------

    assign m0_to_s0 =
        (m0_awaddr >= 32'h00000000) &&
        (m0_awaddr <= 32'h0000FFFF);

    assign m0_to_s1 =
        (m0_awaddr >= 32'h00010000) &&
        (m0_awaddr <= 32'h0001FFFF);

    assign m1_to_s0 =
        (m1_awaddr >= 32'h00000000) &&
        (m1_awaddr <= 32'h0000FFFF);

    assign m1_to_s1 =
        (m1_awaddr >= 32'h00010000) &&
        (m1_awaddr <= 32'h0001FFFF);

    // Unmapped write requests
    assign m0_aw_unmapped =
        m0_awvalid && !(m0_to_s0 || m0_to_s1);

    assign m1_aw_unmapped =
        m1_awvalid && !(m1_to_s0 || m1_to_s1);

    // --------------------------------
    // Arbitration requests
    // --------------------------------

    assign s0_wr_req[0] =
        m0_awvalid && m0_write_available && m0_to_s0;

    assign s0_wr_req[1] =
        m1_awvalid && m1_write_available && m1_to_s0;

    assign s1_wr_req[0] =
        m0_awvalid && m0_write_available && m0_to_s1;

    assign s1_wr_req[1] =
        m1_awvalid && m1_write_available && m1_to_s1;

    // --------------------------------
    // AW acceptance handshakes
    // --------------------------------

    assign s0_wr_grant_accept = s0_awvalid && s0_awready;
    assign s1_wr_grant_accept = s1_awvalid && s1_awready;

    // Owner encoding:
    // 0 = M0
    // 1 = M1
    assign s0_aw_owner = (s0_wr_grant == 2'b10);
    assign s1_aw_owner = (s1_wr_grant == 2'b10);

    // --------------------------------
    // AW routing
    // --------------------------------

    always @(*) begin

        // Master READY defaults
        m0_awready = 1'b0;
        m1_awready = 1'b0;

        // Slave 0 defaults
        s0_awid     = 0;
        s0_awaddr   = 0;
        s0_awlen    = 0;
        s0_awsize   = 0;
        s0_awburst  = 0;
        s0_awlock   = 0;
        s0_awcache  = 0;
        s0_awprot   = 0;
        s0_awqos    = 0;
        s0_awregion = 0;
        s0_awvalid  = 0;

        // Slave 1 defaults
        s1_awid     = 0;
        s1_awaddr   = 0;
        s1_awlen    = 0;
        s1_awsize   = 0;
        s1_awburst  = 0;
        s1_awlock   = 0;
        s1_awcache  = 0;
        s1_awprot   = 0;
        s1_awqos    = 0;
        s1_awregion = 0;
        s1_awvalid  = 0;

        // Slave 0 selection
        if (s0_wr_enable) begin

            if (s0_wr_grant == 2'b01) begin

                s0_awid     = m0_awid;
                s0_awaddr   = m0_awaddr;
                s0_awlen    = m0_awlen;
                s0_awsize   = m0_awsize;
                s0_awburst  = m0_awburst;
                s0_awlock   = m0_awlock;
                s0_awcache  = m0_awcache;
                s0_awprot   = m0_awprot;
                s0_awqos    = m0_awqos;
                s0_awregion = m0_awregion;

                s0_awvalid =
                    m0_awvalid && m0_write_available && m0_to_s0;

                if (s0_awvalid)
                    m0_awready = s0_awready;
            end

            else if (s0_wr_grant == 2'b10) begin

                s0_awid     = m1_awid;
                s0_awaddr   = m1_awaddr;
                s0_awlen    = m1_awlen;
                s0_awsize   = m1_awsize;
                s0_awburst  = m1_awburst;
                s0_awlock   = m1_awlock;
                s0_awcache  = m1_awcache;
                s0_awprot   = m1_awprot;
                s0_awqos    = m1_awqos;
                s0_awregion = m1_awregion;

                s0_awvalid =
                    m1_awvalid && m1_write_available && m1_to_s0;

                if (s0_awvalid)
                    m1_awready = s0_awready;
            end
        end

        // Slave 1 selection
        if (s1_wr_enable) begin

            if (s1_wr_grant == 2'b01) begin

                s1_awid     = m0_awid;
                s1_awaddr   = m0_awaddr;
                s1_awlen    = m0_awlen;
                s1_awsize   = m0_awsize;
                s1_awburst  = m0_awburst;
                s1_awlock   = m0_awlock;
                s1_awcache  = m0_awcache;
                s1_awprot   = m0_awprot;
                s1_awqos    = m0_awqos;
                s1_awregion = m0_awregion;

                s1_awvalid =
                    m0_awvalid && m0_write_available && m0_to_s1;

                if (s1_awvalid)
                    m0_awready = s1_awready;
            end

            else if (s1_wr_grant == 2'b10) begin

                s1_awid     = m1_awid;
                s1_awaddr   = m1_awaddr;
                s1_awlen    = m1_awlen;
                s1_awsize   = m1_awsize;
                s1_awburst  = m1_awburst;
                s1_awlock   = m1_awlock;
                s1_awcache  = m1_awcache;
                s1_awprot   = m1_awprot;
                s1_awqos    = m1_awqos;
                s1_awregion = m1_awregion;

                s1_awvalid =
                    m1_awvalid && m1_write_available && m1_to_s1;

                if (s1_awvalid)
                    m1_awready = s1_awready;
            end
        end

    end

endmodule
