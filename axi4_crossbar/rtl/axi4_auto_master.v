
`timescale 1ns / 1ps

module axi4_auto_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter MASTER_ID  = 0,
    parameter BURST_BEATS = 4
)(
    input wire aclk,
    input wire aresetn,
    input wire start,

    // AXI WRITE ADDRESS
    output reg [ID_WIDTH-1:0] m_awid,
    output reg [ADDR_WIDTH-1:0] m_awaddr,
    output reg [7:0] m_awlen,
    output reg [2:0] m_awsize,
    output reg [1:0] m_awburst,
    output reg m_awvalid,
    input wire m_awready,

    // AXI WRITE DATA
    output reg [DATA_WIDTH-1:0] m_wdata,
    output reg [DATA_WIDTH/8-1:0] m_wstrb,
    output reg m_wlast,
    output reg m_wvalid,
    input wire m_wready,

    // AXI WRITE RESPONSE
    input wire [ID_WIDTH-1:0] m_bid,
    input wire [1:0] m_bresp,
    input wire m_bvalid,
    output reg m_bready,

    // AXI READ ADDRESS
    output reg [ID_WIDTH-1:0] m_arid,
    output reg [ADDR_WIDTH-1:0] m_araddr,
    output reg [7:0] m_arlen,
    output reg [2:0] m_arsize,
    output reg [1:0] m_arburst,
    output reg m_arvalid,
    input wire m_arready,

    // AXI READ DATA
    input wire [ID_WIDTH-1:0] m_rid,
    input wire [DATA_WIDTH-1:0] m_rdata,
    input wire [1:0] m_rresp,
    input wire m_rlast,
    input wire m_rvalid,
    output reg m_rready,

    // STATUS
    output reg [31:0] transaction_count,
    output reg error_flag,
    output reg active
);

    // ------------------------------------------------
    // AXI CONFIGURATION
    // ------------------------------------------------

    localparam [7:0] AXI_LEN = BURST_BEATS - 1;
    localparam [2:0] AXI_SIZE = 3'b010;

    // ------------------------------------------------
    // FSM STATES
    // ------------------------------------------------

    localparam IDLE     = 3'd0;
    localparam WRITE_AW = 3'd1;
    localparam WRITE_W  = 3'd2;
    localparam WRITE_B  = 3'd3;
    localparam READ_AR  = 3'd4;
    localparam READ_R   = 3'd5;

    reg [2:0] state;

    // ------------------------------------------------
    // INTERNAL REGISTERS
    // ------------------------------------------------

    reg [7:0] beat_count;

    reg [ADDR_WIDTH-1:0] current_addr;

    reg [DATA_WIDTH-1:0] data_pattern;

    // Expected data for read-data verification
    reg [DATA_WIDTH-1:0] expected_data;

    // ------------------------------------------------
    // ADDRESS GENERATION
    // ------------------------------------------------

    // Both masters access S0 and S1 alternately.
    //
    // Even transaction : S0
    // Odd transaction  : S1
    //
    // M0 and M1 use separate memory regions.

    

function [ADDR_WIDTH-1:0] get_address;

    input [31:0] count;

    reg [ADDR_WIDTH-1:0] offset;
    reg [ADDR_WIDTH-1:0] master_base;

    reg [31:0] transaction_index;
    reg [31:0] transactions_per_region;
    reg [31:0] bytes_per_transaction;

    begin

        // Number of bytes occupied by one burst
        bytes_per_transaction =
            BURST_BEATS * (DATA_WIDTH/8);

        // Each master has a 32 KB region for each slave.
        transactions_per_region =
            32'h8000 / bytes_per_transaction;

        // Alternate between S0 and S1.
        // Wrap the transaction index to stay inside
        // the allocated memory region.
        transaction_index =
            (count >> 1) % transactions_per_region;

        offset =
            transaction_index * bytes_per_transaction;

        // Separate address regions for M0 and M1.
        if (MASTER_ID == 0)
            master_base = 32'h00000000;
        else
            master_base = 32'h00008000;

        // Odd transaction: S1
        // Even transaction: S0
        if (count[0])
            get_address =
                32'h00010000 + master_base + offset;
        else
            get_address =
                master_base + offset;

    end

endfunction


    // ------------------------------------------------
    // MAIN FSM
    // ------------------------------------------------

    always @(posedge aclk or negedge aresetn) begin

        if (!aresetn) begin

            // FSM
            state <= IDLE;

            // WRITE ADDRESS
            m_awid <= MASTER_ID;
            m_awaddr <= 0;
            m_awlen <= AXI_LEN;
            m_awsize <= AXI_SIZE;
            m_awburst <= 2'b01;
            m_awvalid <= 0;

            // WRITE DATA
            m_wdata <= 0;
            m_wstrb <= {DATA_WIDTH/8{1'b1}};
            m_wlast <= 0;
            m_wvalid <= 0;

            // WRITE RESPONSE
            m_bready <= 0;

            // READ ADDRESS
            m_arid <= MASTER_ID;
            m_araddr <= 0;
            m_arlen <= AXI_LEN;
            m_arsize <= AXI_SIZE;
            m_arburst <= 2'b01;
            m_arvalid <= 0;

            // READ DATA
            m_rready <= 0;

            // INTERNAL REGISTERS
            beat_count <= 0;
            current_addr <= 0;
            data_pattern <= 0;
            expected_data <= 0;

            // STATUS
            transaction_count <= 0;
            error_flag <= 0;
            active <= 0;

        end

        else begin

            case (state)

                // ------------------------------------
                // IDLE
                // ------------------------------------

                IDLE: begin

                    m_awvalid <= 0;
                    m_wvalid <= 0;
                    m_bready <= 0;
                    m_arvalid <= 0;
                    m_rready <= 0;

                    if (start) begin

                        active <= 1;

                        current_addr <= get_address(
                            transaction_count
                        );

                        m_awaddr <= get_address(
                            transaction_count
                        );

                        m_awid <= MASTER_ID;
                        m_awlen <= AXI_LEN;
                        m_awsize <= AXI_SIZE;
                        m_awburst <= 2'b01;

                        m_awvalid <= 1;

                        beat_count <= 0;

                        // First write-data beat
                        data_pattern <=
                            (MASTER_ID << 28) |
                            transaction_count;

                        state <= WRITE_AW;

                    end

                end

                // ------------------------------------
                // WRITE ADDRESS CHANNEL
                // ------------------------------------

                WRITE_AW: begin

                    if (m_awvalid && m_awready) begin

                        m_awvalid <= 0;

                        beat_count <= 0;

                        m_wdata <= data_pattern;

                        m_wstrb <=
                            {DATA_WIDTH/8{1'b1}};

                        m_wlast <=
                            (BURST_BEATS == 1);

                        m_wvalid <= 1;

                        state <= WRITE_W;

                    end

                end

                // ------------------------------------
                // WRITE DATA CHANNEL
                // ------------------------------------

                WRITE_W: begin

                    if (m_wvalid && m_wready) begin

                        if (beat_count == BURST_BEATS-1) begin

                            m_wvalid <= 0;
                            m_wlast <= 0;

                            m_bready <= 1;

                            state <= WRITE_B;

                        end

                        else begin

                            beat_count <=
                                beat_count + 1'b1;

                            m_wdata <=
                                m_wdata + 4;

                            m_wlast <=
                                (beat_count == BURST_BEATS-2);

                        end

                    end

                end

                // ------------------------------------
                // WRITE RESPONSE CHANNEL
                // ------------------------------------

                WRITE_B: begin

                    if (m_bvalid && m_bready) begin

                        m_bready <= 0;

                        // Check write response
                        if ((m_bid != MASTER_ID) ||
                            (m_bresp != 2'b00)) begin

                            error_flag <= 1;

                            $display(
                                "[WRITE RESPONSE ERROR] Master %0d | BID=%h | BRESP=%b",
                                MASTER_ID,
                                m_bid,
                                m_bresp
                            );

                        end

                        // Prepare expected first read beat
                        expected_data <= data_pattern;

                        // Read from the same address
                        m_araddr <= current_addr;
                        m_arid <= MASTER_ID;
                        m_arlen <= AXI_LEN;
                        m_arsize <= AXI_SIZE;
                        m_arburst <= 2'b01;

                        m_arvalid <= 1;

                        state <= READ_AR;

                    end

                end

                // ------------------------------------
                // READ ADDRESS CHANNEL
                // ------------------------------------

                READ_AR: begin

                    if (m_arvalid && m_arready) begin

                        m_arvalid <= 0;

                        m_rready <= 1;

                        beat_count <= 0;

                        state <= READ_R;

                    end

                end

                // ------------------------------------
                // READ DATA CHANNEL
                // ------------------------------------

                READ_R: begin

                    if (m_rvalid && m_rready) begin

                        // Check response ID and status
                        if ((m_rid != MASTER_ID) ||
                            (m_rresp != 2'b00)) begin

                            error_flag <= 1;

                            $display(
                                "[READ RESPONSE ERROR] Master %0d | RID=%h | RRESP=%b",
                                MASTER_ID,
                                m_rid,
                                m_rresp
                            );

                        end

                        // --------------------------------
                        // DATA INTEGRITY CHECK
                        // --------------------------------

                        if (m_rdata !== expected_data) begin

                            error_flag <= 1;

                            $display(
                                "[DATA ERROR] Master %0d | Address=%h | Beat=%0d | Expected=%h | Received=%h",
                                MASTER_ID,
                                current_addr,
                                beat_count,
                                expected_data,
                                m_rdata
                            );

                        end

                        // --------------------------------
                        // LAST BEAT CHECK
                        // --------------------------------

                        if (m_rlast) begin

                            if (beat_count != BURST_BEATS-1)
                                error_flag <= 1;

                            m_rready <= 0;

                            transaction_count <=
                                transaction_count + 1'b1;

                            $display(
                                "[DATA PASS] Master %0d | Transaction=%0d | Address=%h",
                                MASTER_ID,
                                transaction_count,
                                current_addr
                            );

                            state <= IDLE;

                        end

                        else begin

                            // RLAST must be asserted on
                            // the expected final beat.
                            if (beat_count == BURST_BEATS-1)
                                error_flag <= 1;

                            beat_count <=
                                beat_count + 1'b1;

                            // Expected next 32-bit word
                            expected_data <=
                                expected_data + 4;

                        end

                    end

                end

                // ------------------------------------
                // DEFAULT
                // ------------------------------------

                default: begin

                    state <= IDLE;

                    m_awvalid <= 0;
                    m_wvalid <= 0;
                    m_bready <= 0;
                    m_arvalid <= 0;
                    m_rready <= 0;

                    error_flag <= 1;

                end

            endcase

        end

    end

    // ------------------------------------------------
    // PARAMETER SANITY CHECKS
    // ------------------------------------------------

    initial begin

        if (DATA_WIDTH != 32)
            $error(
                "This initial generator requires DATA_WIDTH=32"
            );

        if ((BURST_BEATS < 1) ||
            (BURST_BEATS > 16))
            $error(
                "BURST_BEATS must be between 1 and 16"
            );

        if (ADDR_WIDTH != 32)
            $error(
                "This initial generator requires ADDR_WIDTH=32"
            );

    end

endmodule
