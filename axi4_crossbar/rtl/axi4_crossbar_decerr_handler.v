
`timescale 1ns / 1ps

module axi4_crossbar_decerr_handler #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4
)(
    input wire aclk,
    input wire aresetn,

    // ------------------------------------------------
    // Unmapped READ address input
    // ------------------------------------------------
    input wire [ID_WIDTH-1:0] m_arid,
    input wire [7:0] m_arlen,
    input wire m_arvalid,
    output wire m_arready,

    // ------------------------------------------------
    // Read DECERR response output
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] m_rid,
    output wire [DATA_WIDTH-1:0] m_rdata,
    output wire [1:0] m_rresp,
    output wire m_rlast,
    output wire m_rvalid,
    input wire m_rready,

    // ------------------------------------------------
    // Unmapped WRITE address input
    // ------------------------------------------------
    input wire [ID_WIDTH-1:0] m_awid,
    input wire [7:0] m_awlen,
    input wire m_awvalid,
    output wire m_awready,

    // ------------------------------------------------
    // Write data input
    // ------------------------------------------------
    input wire [DATA_WIDTH-1:0] m_wdata,
    input wire [DATA_WIDTH/8-1:0] m_wstrb,
    input wire m_wlast,
    input wire m_wvalid,
    output wire m_wready,

    // ------------------------------------------------
    // Write DECERR response output
    // ------------------------------------------------
    output wire [ID_WIDTH-1:0] m_bid,
    output wire [1:0] m_bresp,
    output wire m_bvalid,
    input wire m_bready
);

    localparam [1:0] DECERR = 2'b11;

    // =================================================
    // READ DECERR GENERATOR
    // =================================================

    reg read_active;
    reg [ID_WIDTH-1:0] read_id;
    reg [8:0] read_beats_remaining;

    assign m_arready = !read_active;

    assign m_rid   = read_id;
    assign m_rdata = {DATA_WIDTH{1'b0}};
    assign m_rresp = DECERR;
    assign m_rvalid = read_active;
    assign m_rlast = (read_beats_remaining == 9'd1);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_active         <= 1'b0;
            read_id             <= {ID_WIDTH{1'b0}};
            read_beats_remaining <= 9'd0;
        end
        else begin

            // Accept unmapped AR request
            if (m_arvalid && m_arready) begin
                read_active          <= 1'b1;
                read_id              <= m_arid;
                read_beats_remaining <= {1'b0, m_arlen} + 9'd1;
            end

            // Advance only when the master accepts a beat
            else if (read_active && m_rvalid && m_rready) begin
                if (read_beats_remaining == 9'd1) begin
                    read_active          <= 1'b0;
                    read_beats_remaining <= 9'd0;
                end
                else begin
                    read_beats_remaining <=
                        read_beats_remaining - 9'd1;
                end
            end
        end
    end

    // =================================================
    // WRITE DECERR GENERATOR
    // =================================================

    localparam [1:0] WRITE_IDLE = 2'b00;
    localparam [1:0] WRITE_DATA = 2'b01;
    localparam [1:0] WRITE_RESP = 2'b10;

    reg [1:0] write_state;
    reg [ID_WIDTH-1:0] write_id;
    reg [8:0] write_beats_remaining;

    assign m_awready = (write_state == WRITE_IDLE);

    assign m_wready = (write_state == WRITE_DATA);

    assign m_bid = write_id;
    assign m_bresp = DECERR;
    assign m_bvalid = (write_state == WRITE_RESP);

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state          <= WRITE_IDLE;
            write_id             <= {ID_WIDTH{1'b0}};
            write_beats_remaining <= 9'd0;
        end
        else begin
            case (write_state)

                WRITE_IDLE: begin
                    if (m_awvalid && m_awready) begin
                        write_id <= m_awid;
                        write_beats_remaining <=
                            {1'b0, m_awlen} + 9'd1;
                        write_state <= WRITE_DATA;
                    end
                end

                WRITE_DATA: begin
                    if (m_wvalid && m_wready) begin

                        if (write_beats_remaining == 9'd1) begin
                            write_beats_remaining <= 9'd0;
                            write_state <= WRITE_RESP;
                        end
                        else begin
                            write_beats_remaining <=
                                write_beats_remaining - 9'd1;
                        end

                    end
                end

                WRITE_RESP: begin
                    if (m_bvalid && m_bready) begin
                        write_state <= WRITE_IDLE;
                    end
                end

                default: begin
                    write_state <= WRITE_IDLE;
                end

            endcase
        end
    end

endmodule
