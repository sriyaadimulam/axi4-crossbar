
`timescale 1ns / 1ps

module axi4_crossbar_b_router #(
    parameter ID_WIDTH = 4
)(
    input wire aclk,
    input wire aresetn,

    // Master 0 B interface
    output wire [ID_WIDTH-1:0] m0_bid,
    output wire [1:0] m0_bresp,
    output wire m0_bvalid,
    input wire m0_bready,

    // Master 1 B interface
    output wire [ID_WIDTH-1:0] m1_bid,
    output wire [1:0] m1_bresp,
    output wire m1_bvalid,
    input wire m1_bready,

    // Slave 0 B interface
    input wire [ID_WIDTH-1:0] s0_bid,
    input wire [1:0] s0_bresp,
    input wire s0_bvalid,
    output wire s0_bready,

    // Slave 1 B interface
    input wire [ID_WIDTH-1:0] s1_bid,
    input wire [1:0] s1_bresp,
    input wire s1_bvalid,
    output wire s1_bready,

    // AW ownership information
    input wire s0_aw_accept,
    input wire s0_aw_owner,
    input wire s1_aw_accept,
    input wire s1_aw_owner
);

    // Write response ownership registers
    reg s0_b_active;
    reg s0_b_owner;

    reg s1_b_active;
    reg s1_b_owner;

    // ------------------------------------------------
    // Slave 0 response routing
    // ------------------------------------------------

    assign m0_bid =
        (s0_b_active && s0_b_owner == 1'b0) ?
        s0_bid :
        (s1_b_active && s1_b_owner == 1'b0) ?
        s1_bid : {ID_WIDTH{1'b0}};

    assign m0_bresp =
        (s0_b_active && s0_b_owner == 1'b0) ?
        s0_bresp :
        (s1_b_active && s1_b_owner == 1'b0) ?
        s1_bresp : 2'b00;

    assign m0_bvalid =
        (s0_b_active && s0_b_owner == 1'b0 && s0_bvalid) ||
        (s1_b_active && s1_b_owner == 1'b0 && s1_bvalid);

    // ------------------------------------------------
    // Master 1 response routing
    // ------------------------------------------------

    assign m1_bid =
        (s0_b_active && s0_b_owner == 1'b1) ?
        s0_bid :
        (s1_b_active && s1_b_owner == 1'b1) ?
        s1_bid : {ID_WIDTH{1'b0}};

    assign m1_bresp =
        (s0_b_active && s0_b_owner == 1'b1) ?
        s0_bresp :
        (s1_b_active && s1_b_owner == 1'b1) ?
        s1_bresp : 2'b00;

    assign m1_bvalid =
        (s0_b_active && s0_b_owner == 1'b1 && s0_bvalid) ||
        (s1_b_active && s1_b_owner == 1'b1 && s1_bvalid);

    // ------------------------------------------------
    // BREADY routing
    // ------------------------------------------------

    assign s0_bready =
        s0_b_active ?
        ((s0_b_owner == 1'b0) ? m0_bready : m1_bready) :
        1'b0;

    assign s1_bready =
        s1_b_active ?
        ((s1_b_owner == 1'b0) ? m0_bready : m1_bready) :
        1'b0;

    // ------------------------------------------------
    // Response ownership management
    // ------------------------------------------------

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s0_b_active <= 1'b0;
            s0_b_owner  <= 1'b0;

            s1_b_active <= 1'b0;
            s1_b_owner  <= 1'b0;
        end
        else begin

            // Slave 0 response ownership
            if (s0_aw_accept) begin
                s0_b_active <= 1'b1;
                s0_b_owner  <= s0_aw_owner;
            end
            else if (s0_b_active && s0_bvalid && s0_bready) begin
                s0_b_active <= 1'b0;
            end

            // Slave 1 response ownership
            if (s1_aw_accept) begin
                s1_b_active <= 1'b1;
                s1_b_owner  <= s1_aw_owner;
            end
            else if (s1_b_active && s1_bvalid && s1_bready) begin
                s1_b_active <= 1'b0;
            end
        end
    end

endmodule
