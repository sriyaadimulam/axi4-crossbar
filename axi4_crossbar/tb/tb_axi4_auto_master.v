`timescale 1ns / 1ps

module tb_axi4_auto_master;

    // --------------------------------------------------
    // Parameters
    // --------------------------------------------------
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter ID_WIDTH   = 4;
    parameter BURST_BEATS = 4;

    // --------------------------------------------------
    // Clock and reset
    // --------------------------------------------------
    reg aclk;
    reg aresetn;
    reg start;

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // --------------------------------------------------
    // AXI master signals
    // --------------------------------------------------
    wire [ID_WIDTH-1:0]   awid;
    wire [ADDR_WIDTH-1:0] awaddr;
    wire [7:0]            awlen;
    wire [2:0]            awsize;
    wire [1:0]            awburst;
    wire                  awvalid;
    reg                   awready;

    wire [DATA_WIDTH-1:0] wdata;
    wire [DATA_WIDTH/8-1:0] wstrb;
    wire                  wlast;
    wire                  wvalid;
    reg                   wready;

    reg [ID_WIDTH-1:0] bid;
    reg [1:0] bresp;
    reg bvalid;
    wire bready;

    wire [ID_WIDTH-1:0]   arid;
    wire [ADDR_WIDTH-1:0] araddr;
    wire [7:0]            arlen;
    wire [2:0]            arsize;
    wire [1:0]            arburst;
    wire                  arvalid;
    reg                   arready;

    reg [ID_WIDTH-1:0] rid;
    reg [DATA_WIDTH-1:0] rdata;
    reg [1:0] rresp;
    reg rlast;
    reg rvalid;
    wire rready;

    wire [31:0] transaction_count;
    wire error_flag;
    wire active;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    axi4_auto_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .MASTER_ID(0),
        .BURST_BEATS(BURST_BEATS)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .start(start),

        .m_awid(awid),
        .m_awaddr(awaddr),
        .m_awlen(awlen),
        .m_awsize(awsize),
        .m_awburst(awburst),
        .m_awvalid(awvalid),
        .m_awready(awready),

        .m_wdata(wdata),
        .m_wstrb(wstrb),
        .m_wlast(wlast),
        .m_wvalid(wvalid),
        .m_wready(wready),

        .m_bid(bid),
        .m_bresp(bresp),
        .m_bvalid(bvalid),
        .m_bready(bready),

        .m_arid(arid),
        .m_araddr(araddr),
        .m_arlen(arlen),
        .m_arsize(arsize),
        .m_arburst(arburst),
        .m_arvalid(arvalid),
        .m_arready(arready),

        .m_rid(rid),
        .m_rdata(rdata),
        .m_rresp(rresp),
        .m_rlast(rlast),
        .m_rvalid(rvalid),
        .m_rready(rready),

        .transaction_count(transaction_count),
        .error_flag(error_flag),
        .active(active)
    );

    // --------------------------------------------------
    // Simple AXI slave response model
    // --------------------------------------------------
    reg [ID_WIDTH-1:0] captured_awid;
    reg [7:0] captured_awlen;
    integer write_beat_count;

    reg [ID_WIDTH-1:0] captured_arid;
    reg [7:0] captured_arlen;
    reg [7:0] read_beat_count;
    reg read_active;

    reg protocol_error;
    integer write_burst_count;
    integer read_burst_count;

    // Slave response model
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready          <= 1'b1;
            wready           <= 1'b1;
            arready          <= 1'b1;

            bvalid           <= 1'b0;
            bid              <= 0;
            bresp            <= 2'b00;

            rvalid           <= 1'b0;
            rid              <= 0;
            rdata            <= 0;
            rresp            <= 2'b00;
            rlast            <= 1'b0;

            captured_awid    <= 0;
            captured_awlen   <= 0;
            write_beat_count <= 0;

            captured_arid    <= 0;
            captured_arlen   <= 0;
            read_beat_count  <= 0;
            read_active      <= 1'b0;

            protocol_error   <= 1'b0;
            write_burst_count <= 0;
            read_burst_count  <= 0;
        end
        else begin

            // ------------------------------
            // AW channel
            // ------------------------------
            if (awvalid && awready) begin
                captured_awid    <= awid;
                captured_awlen   <= awlen;
                write_beat_count <= 0;

                if (awsize != 3'b010 || awburst != 2'b01)
                    protocol_error <= 1'b1;

                if (awid != 0)
                    protocol_error <= 1'b1;
            end

            // ------------------------------
            // W channel
            // ------------------------------
            if (wvalid && wready) begin

                if (wlast != (write_beat_count == captured_awlen))
                    protocol_error <= 1'b1;

                if (write_beat_count == captured_awlen) begin
                    bvalid <= 1'b1;
                    bid <= captured_awid;
                    bresp <= 2'b00;

                    write_beat_count <= 0;
                    write_burst_count <= write_burst_count + 1;
                end
                else begin
                    write_beat_count <= write_beat_count + 1;
                end
            end

            // ------------------------------
            // B channel
            // ------------------------------
            if (bvalid && bready)
                bvalid <= 1'b0;

            // ------------------------------
            // AR channel
            // ------------------------------
            if (arvalid && arready && !read_active) begin
                captured_arid   <= arid;
                captured_arlen  <= arlen;
                read_beat_count <= 0;
                read_active     <= 1'b1;

                rid   <= arid;
                rdata <= araddr;
                rresp <= 2'b00;
                rlast <= (arlen == 0);
                rvalid <= 1'b1;

                if (arsize != 3'b010 || arburst != 2'b01)
                    protocol_error <= 1'b1;

                if (arid != 0)
                    protocol_error <= 1'b1;
            end

            // ------------------------------
            // R channel
            // ------------------------------
            if (rvalid && rready) begin

                if (rid != captured_arid || rresp != 2'b00)
                    protocol_error <= 1'b1;

                if (rlast != (read_beat_count == captured_arlen))
                    protocol_error <= 1'b1;

                if (read_beat_count == captured_arlen) begin
                    rvalid <= 1'b0;
                    rlast <= 1'b0;
                    read_active <= 1'b0;
                    read_beat_count <= 0;
                    read_burst_count <= read_burst_count + 1;
                end
                else begin
                    read_beat_count <= read_beat_count + 1;
                    rdata <= rdata + 4;
                    rlast <= (read_beat_count + 1 == captured_arlen);
                end
            end
        end
    end

    // --------------------------------------------------
    // Test utilities
    // --------------------------------------------------
    integer checks;
    integer failures;

    task check_result;
        input condition;
        input [8*100-1:0] message;
        begin
            checks = checks + 1;

            if (condition) begin
                $display("[PASS] %0s", message);
            end
            else begin
                $display("[FAIL] %0s", message);
                failures = failures + 1;
            end
        end
    endtask

    // --------------------------------------------------
    // Main test sequence
    // --------------------------------------------------
    integer timeout_count;

    initial begin
        checks = 0;
        failures = 0;

        $display("------------------------------------------");
        $display(" AXI4 AUTO MASTER TESTBENCH");
        $display("------------------------------------------");

        // Reset
        aresetn = 0;
        start = 0;

        repeat (5) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        repeat (3) @(posedge aclk);

        // Start automatic traffic
        @(negedge aclk);
        start = 1;

        // Wait for two completed write-read transactions
        timeout_count = 0;

        while (transaction_count < 2 && timeout_count < 2000) begin
            @(posedge aclk);
            timeout_count = timeout_count + 1;
        end

        @(negedge aclk);

        check_result(transaction_count >= 2,
                     "Two complete write-read transactions");

        check_result(write_burst_count >= 2,
                     "At least two write bursts received");

        check_result(read_burst_count >= 2,
                     "At least two read bursts received");

        check_result(!error_flag,
                     "Master error flag remains low");

        check_result(!protocol_error,
                     "AXI slave model detected no protocol errors");

        check_result(active,
                     "Master active signal asserted");

        check_result(timeout_count < 2000,
                     "Transaction completion watchdog");

        $display("------------------------------------------");
        $display("TEST SUMMARY");
        $display("Checks run : %0d", checks);
        $display("Failures   : %0d", failures);
        $display("Transactions completed : %0d", transaction_count);
        $display("Write bursts received  : %0d", write_burst_count);
        $display("Read bursts received   : %0d", read_burst_count);
        $display("------------------------------------------");

        if (failures == 0)
            $display("ALL AUTO MASTER TESTS PASSED");
        else
            $display("AUTO MASTER TESTS FAILED");

        $finish;
    end

    // --------------------------------------------------
    // Global watchdog
    // --------------------------------------------------
    initial begin
        #200000;

        $display("[FAIL] Global simulation timeout");
        $finish;
    end

endmodule
