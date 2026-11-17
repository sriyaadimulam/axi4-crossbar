`timescale 1ns / 1ps

module tb_axi4_simple_memory;

    // ------------------------------------------------
    // Clock and reset
    // ------------------------------------------------
    reg aclk;
    reg aresetn;

    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // ------------------------------------------------
    // AXI signals
    // ------------------------------------------------
    reg [3:0] awid;
    reg [31:0] awaddr;
    reg [7:0] awlen;
    reg [2:0] awsize;
    reg [1:0] awburst;
    reg awvalid;
    wire awready;

    reg [31:0] wdata;
    reg [3:0] wstrb;
    reg wlast;
    reg wvalid;
    wire wready;

    wire [3:0] bid;
    wire [1:0] bresp;
    wire bvalid;
    reg bready;

    reg [3:0] arid;
    reg [31:0] araddr;
    reg [7:0] arlen;
    reg [2:0] arsize;
    reg [1:0] arburst;
    reg arvalid;
    wire arready;

    wire [3:0] rid;
    wire [31:0] rdata;
    wire [1:0] rresp;
    wire rlast;
    wire rvalid;
    reg rready;

    // ------------------------------------------------
    // DUT
    // ------------------------------------------------
    axi4_simple_memory #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .ID_WIDTH(4),
        .BASE_ADDR(32'h00000000),
        .MEM_WORDS(16384)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_awid(awid),
        .s_awaddr(awaddr),
        .s_awlen(awlen),
        .s_awsize(awsize),
        .s_awburst(awburst),
        .s_awvalid(awvalid),
        .s_awready(awready),

        .s_wdata(wdata),
        .s_wstrb(wstrb),
        .s_wlast(wlast),
        .s_wvalid(wvalid),
        .s_wready(wready),

        .s_bid(bid),
        .s_bresp(bresp),
        .s_bvalid(bvalid),
        .s_bready(bready),

        .s_arid(arid),
        .s_araddr(araddr),
        .s_arlen(arlen),
        .s_arsize(arsize),
        .s_arburst(arburst),
        .s_arvalid(arvalid),
        .s_arready(arready),

        .s_rid(rid),
        .s_rdata(rdata),
        .s_rresp(rresp),
        .s_rlast(rlast),
        .s_rvalid(rvalid),
        .s_rready(rready)
    );

    // ------------------------------------------------
    // Test data
    // ------------------------------------------------
    reg [31:0] expected [0:3];

    integer checks;
    integer failures;
    integer k;

    // ------------------------------------------------
    // Check task
    // ------------------------------------------------
    task check_result;
        input condition;
        input [8*100-1:0] message;
        begin
            checks = checks + 1;

            if (condition)
                $display("[PASS] %0s", message);
            else begin
                $display("[FAIL] %0s", message);
                failures = failures + 1;
            end
        end
    endtask

    // ------------------------------------------------
    // Write four words using one INCR burst
    // ------------------------------------------------
    
task perform_write;
    integer j;
    begin
        $display("\nStarting four-beat write burst...");

        // Write address
        @(negedge aclk);
        awid = 4'h3;
        awaddr = 32'h00000000;
        awlen = 8'd3;
        awsize = 3'b010;
        awburst = 2'b01;
        awvalid = 1'b1;

        while (!awready)
            @(negedge aclk);

        @(posedge aclk);
        @(negedge aclk);
        awvalid = 1'b0;

        // Write data beats
        for (j = 0; j < 4; j = j + 1) begin

            wdata = expected[j];
            wstrb = 4'b1111;
            wlast = (j == 3);
            wvalid = 1'b1;

            while (!wready)
                @(negedge aclk);

            @(posedge aclk);
            @(negedge aclk);
            wvalid = 1'b0;

        end

        // Wait for write response
        while (!bvalid)
            @(negedge aclk);

        check_result(bid == 4'h3,
                     "Write response ID is correct");

        check_result(bresp == 2'b00,
                     "Write response is OKAY");

        @(posedge aclk);
        @(negedge aclk);

    end
endtask


    // ------------------------------------------------
    // Read four words using one INCR burst
    // ------------------------------------------------
    
task perform_read;
    integer j;
    begin
        $display("\nStarting four-beat read burst...");

        // Read address
        @(negedge aclk);
        arid = 4'h5;
        araddr = 32'h00000000;
        arlen = 8'd3;
        arsize = 3'b010;
        arburst = 2'b01;
        arvalid = 1'b1;

        while (!arready)
            @(negedge aclk);

        @(posedge aclk);
        @(negedge aclk);
        arvalid = 1'b0;

        // Read response beats
        for (j = 0; j < 4; j = j + 1) begin

            while (!rvalid)
                @(negedge aclk);

            check_result(rid == 4'h5,
                         "Read response ID is correct");

            check_result(rresp == 2'b00,
                         "Read response is OKAY");

            check_result(rdata === expected[j],
                         "Read data matches written data");

            check_result(rlast == (j == 3),
                         "RLAST position is correct");

            @(posedge aclk);
            @(negedge aclk);

        end

    end
endtask


    // ------------------------------------------------
    // Main test
    // ------------------------------------------------
    initial begin

        checks = 0;
        failures = 0;

        // Expected memory contents
        expected[0] = 32'h12345678;
        expected[1] = 32'hAABBCCDD;
        expected[2] = 32'hDEADBEEF;
        expected[3] = 32'hCAFEBABE;

        // Initial values
        aresetn = 0;

        awid = 0;
        awaddr = 0;
        awlen = 0;
        awsize = 0;
        awburst = 0;
        awvalid = 0;

        wdata = 0;
        wstrb = 0;
        wlast = 0;
        wvalid = 0;

        bready = 1;

        arid = 0;
        araddr = 0;
        arlen = 0;
        arsize = 0;
        arburst = 0;
        arvalid = 0;

        rready = 1;

        $display("------------------------------------------");
        $display(" AXI4 SIMPLE MEMORY TESTBENCH");
        $display("------------------------------------------");

        // Reset
        repeat (5) @(posedge aclk);

        @(negedge aclk);
        aresetn = 1;

        repeat (2) @(posedge aclk);

        // Execute write and read
        perform_write;
        perform_read;

        // Summary
        $display("\n------------------------------------------");
        $display("TEST SUMMARY");
        $display("Checks run : %0d", checks);
        $display("Failures   : %0d", failures);
        $display("------------------------------------------");

        if (failures == 0)
            $display("ALL MEMORY TESTS PASSED");
        else
            $display("MEMORY TESTS FAILED");

        $finish;
    end

    // ------------------------------------------------
    // Global watchdog
    // ------------------------------------------------
    initial begin
        #200000;
        $display("[FAIL] Global simulation timeout");
        $finish;
    end

endmodule
