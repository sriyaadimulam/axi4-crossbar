
`timescale 1ns / 1ps

module axi4_crossbar_r_router #(
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input wire aclk,
    input wire aresetn,

    // Accepted read-address transactions.
    // owner = 0: M0, owner = 1: M1
    input wire s0_ar_accept,
    input wire s0_ar_owner,

    input wire s1_ar_accept,
    input wire s1_ar_owner,

    // Slave 0 R interface
    input wire [ID_WIDTH-1:0] s0_rid,
    input wire [DATA_WIDTH-1:0] s0_rdata,
    input wire [1:0] s0_rresp,
    input wire s0_rlast,
    input wire s0_rvalid,
    output reg s0_rready,

    // Slave 1 R interface
    input wire [ID_WIDTH-1:0] s1_rid,
    input wire [DATA_WIDTH-1:0] s1_rdata,
    input wire [1:0] s1_rresp,
    input wire s1_rlast,
    input wire s1_rvalid,
    output reg s1_rready,

    // Master 0 R interface
    output reg [ID_WIDTH-1:0] m0_rid,
    output reg [DATA_WIDTH-1:0] m0_rdata,
    output reg [1:0] m0_rresp,
    output reg m0_rlast,
    output reg m0_rvalid,
    input wire m0_rready,

    // Master 1 R interface
    output reg [ID_WIDTH-1:0] m1_rid,
    output reg [DATA_WIDTH-1:0] m1_rdata,
    output reg [1:0] m1_rresp,
    output reg m1_rlast,
    output reg m1_rvalid,
    input wire m1_rready,

    // Ownership status
    output reg s0_owner_valid,
    output reg s1_owner_valid,
    output reg s0_owner,
    output reg s1_owner
);

    // --------------------------------
    // Capture read transaction owners
    // --------------------------------

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s0_owner_valid <= 1'b0;
            s1_owner_valid <= 1'b0;

            s0_owner <= 1'b0;
            s1_owner <= 1'b0;
        end
        else begin

            // Slave 0 ownership
            if (s0_ar_accept) begin
                s0_owner_valid <= 1'b1;
                s0_owner <= s0_ar_owner;
            end
            else if (s0_rvalid && s0_rready && s0_rlast) begin
                s0_owner_valid <= 1'b0;
            end

            // Slave 1 ownership
            if (s1_ar_accept) begin
                s1_owner_valid <= 1'b1;
                s1_owner <= s1_ar_owner;
            end
            else if (s1_rvalid && s1_rready && s1_rlast) begin
                s1_owner_valid <= 1'b0;
            end
        end
    end

    // --------------------------------
    // Route slave responses to masters
    // --------------------------------

    always @(*) begin

        // Default master outputs
        m0_rid = 0;
        m0_rdata = 0;
        m0_rresp = 0;
        m0_rlast = 0;
        m0_rvalid = 0;

        m1_rid = 0;
        m1_rdata = 0;
        m1_rresp = 0;
        m1_rlast = 0;
        m1_rvalid = 0;

        // Default slave READY outputs
        s0_rready = 0;
        s1_rready = 0;

        // Slave 0 response routing
        if (s0_owner_valid && s0_rvalid) begin

            if (s0_owner == 1'b0) begin
                m0_rid = s0_rid;
                m0_rdata = s0_rdata;
                m0_rresp = s0_rresp;
                m0_rlast = s0_rlast;
                m0_rvalid = 1'b1;

                s0_rready = m0_rready;
            end
            else begin
                m1_rid = s0_rid;
                m1_rdata = s0_rdata;
                m1_rresp = s0_rresp;
                m1_rlast = s0_rlast;
                m1_rvalid = 1'b1;

                s0_rready = m1_rready;
            end
        end

        // Slave 1 response routing
        if (s1_owner_valid && s1_rvalid) begin

            if (s1_owner == 1'b0) begin
                m0_rid = s1_rid;
                m0_rdata = s1_rdata;
                m0_rresp = s1_rresp;
                m0_rlast = s1_rlast;
                m0_rvalid = 1'b1;

                s1_rready = m0_rready;
            end
            else begin
                m1_rid = s1_rid;
                m1_rdata = s1_rdata;
                m1_rresp = s1_rresp;
                m1_rlast = s1_rlast;
                m1_rvalid = 1'b1;

                s1_rready = m1_rready;
            end
        end

    end

endmodule
