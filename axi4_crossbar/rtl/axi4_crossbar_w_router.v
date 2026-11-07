
`timescale 1ns / 1ps

module axi4_crossbar_w_router #(
    parameter DATA_WIDTH = 32
)(
    input wire aclk,
    input wire aresetn,

    // Master 0 write data interface
    input wire [DATA_WIDTH-1:0] m0_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m0_wstrb,
    input wire m0_wlast,
    input wire m0_wvalid,
    output wire m0_wready,

    // Master 1 write data interface
    input wire [DATA_WIDTH-1:0] m1_wdata,
    input wire [(DATA_WIDTH/8)-1:0] m1_wstrb,
    input wire m1_wlast,
    input wire m1_wvalid,
    output wire m1_wready,

    // Slave 0 write data interface
    output wire [DATA_WIDTH-1:0] s0_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s0_wstrb,
    output wire s0_wlast,
    output wire s0_wvalid,
    input wire s0_wready,

    // Slave 1 write data interface
    output wire [DATA_WIDTH-1:0] s1_wdata,
    output wire [(DATA_WIDTH/8)-1:0] s1_wstrb,
    output wire s1_wlast,
    output wire s1_wvalid,
    input wire s1_wready,

    // AW handshake information
    input wire s0_aw_accept,
    input wire s0_aw_owner,
    input wire s1_aw_accept,
    input wire s1_aw_owner
);

    // Ownership registers
    reg s0_write_active;
    reg s0_write_owner;

    reg s1_write_active;
    reg s1_write_owner;

    // Slave 0 routing
    assign s0_wdata =
        (s0_write_owner == 1'b0) ? m0_wdata : m1_wdata;

    assign s0_wstrb =
        (s0_write_owner == 1'b0) ? m0_wstrb : m1_wstrb;

    assign s0_wlast =
        (s0_write_owner == 1'b0) ? m0_wlast : m1_wlast;

    assign s0_wvalid =
        s0_write_active &&
        ((s0_write_owner == 1'b0) ? m0_wvalid : m1_wvalid);

    // Slave 1 routing
    assign s1_wdata =
        (s1_write_owner == 1'b0) ? m0_wdata : m1_wdata;

    assign s1_wstrb =
        (s1_write_owner == 1'b0) ? m0_wstrb : m1_wstrb;

    assign s1_wlast =
        (s1_write_owner == 1'b0) ? m0_wlast : m1_wlast;

    assign s1_wvalid =
        s1_write_active &&
        ((s1_write_owner == 1'b0) ? m0_wvalid : m1_wvalid);

    // Master ready routing
    assign m0_wready =
        ((s0_write_active && s0_write_owner == 1'b0) &&
          s0_wready) ||
        ((s1_write_active && s1_write_owner == 1'b0) &&
          s1_wready);

    assign m1_wready =
        ((s0_write_active && s0_write_owner == 1'b1) &&
          s0_wready) ||
        ((s1_write_active && s1_write_owner == 1'b1) &&
          s1_wready);

    // Ownership management
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s0_write_active <= 1'b0;
            s0_write_owner  <= 1'b0;

            s1_write_active <= 1'b0;
            s1_write_owner  <= 1'b0;
        end
        else begin

            // Capture Slave 0 ownership on AW acceptance
            if (s0_aw_accept) begin
                s0_write_active <= 1'b1;
                s0_write_owner  <= s0_aw_owner;
            end
            else if (s0_write_active &&
                     s0_wvalid && s0_wready && s0_wlast) begin
                s0_write_active <= 1'b0;
            end

            // Capture Slave 1 ownership on AW acceptance
            if (s1_aw_accept) begin
                s1_write_active <= 1'b1;
                s1_write_owner  <= s1_aw_owner;
            end
            else if (s1_write_active &&
                     s1_wvalid && s1_wready && s1_wlast) begin
                s1_write_active <= 1'b0;
            end
        end
    end

endmodule
