`timescale 1ns / 1ps

module tb_axi4_crossbar_top;

    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam ID_WIDTH   = 4;

    reg aclk, aresetn;
    reg [1:0] arb_policy;

    // MASTER 0
    reg [3:0] m0_awid, m0_arid;
    reg [31:0] m0_awaddr, m0_araddr;
    reg [7:0] m0_awlen, m0_arlen;
    reg [2:0] m0_awsize, m0_arsize;
    reg [1:0] m0_awburst, m0_arburst;
    reg m0_awlock, m0_arlock;
    reg [3:0] m0_awcache, m0_arcache;
    reg [2:0] m0_awprot, m0_arprot;
    reg [3:0] m0_awqos, m0_arqos;
    reg [3:0] m0_awregion, m0_arregion;
    reg m0_awvalid, m0_arvalid;

    reg [31:0] m0_wdata;
    reg [3:0] m0_wstrb;
    reg m0_wlast, m0_wvalid;

    wire m0_awready, m0_wready;
    wire [3:0] m0_bid, m0_rid;
    wire [1:0] m0_bresp, m0_rresp;
    wire m0_bvalid, m0_rvalid, m0_rlast;
    wire [31:0] m0_rdata;
    reg m0_bready, m0_rready;
    wire m0_arready;

    // MASTER 1
    reg [3:0] m1_awid, m1_arid;
    reg [31:0] m1_awaddr, m1_araddr;
    reg [7:0] m1_awlen, m1_arlen;
    reg [2:0] m1_awsize, m1_arsize;
    reg [1:0] m1_awburst, m1_arburst;
    reg m1_awlock, m1_arlock;
    reg [3:0] m1_awcache, m1_arcache;
    reg [2:0] m1_awprot, m1_arprot;
    reg [3:0] m1_awqos, m1_arqos;
    reg [3:0] m1_awregion, m1_arregion;
    reg m1_awvalid, m1_arvalid;

    reg [31:0] m1_wdata;
    reg [3:0] m1_wstrb;
    reg m1_wlast, m1_wvalid;

    wire m1_awready, m1_wready;
    wire [3:0] m1_bid, m1_rid;
    wire [1:0] m1_bresp, m1_rresp;
    wire m1_bvalid, m1_rvalid, m1_rlast;
    wire [31:0] m1_rdata;
    reg m1_bready, m1_rready;
    wire m1_arready;

    // SLAVE 0
    wire [3:0] s0_awid, s0_arid;
    wire [31:0] s0_awaddr, s0_araddr;
    wire [7:0] s0_awlen, s0_arlen;
    wire [2:0] s0_awsize, s0_arsize;
    wire [1:0] s0_awburst, s0_arburst;
    wire s0_awlock, s0_arlock;
    wire [3:0] s0_awcache, s0_arcache;
    wire [2:0] s0_awprot, s0_arprot;
    wire [3:0] s0_awqos, s0_arqos;
    wire [3:0] s0_awregion, s0_arregion;
    wire s0_awvalid, s0_arvalid;
    reg s0_awready, s0_arready;

    wire [31:0] s0_wdata;
    wire [3:0] s0_wstrb;
    wire s0_wlast, s0_wvalid;
    reg s0_wready;

    reg [3:0] s0_bid, s0_rid;
    reg [1:0] s0_bresp, s0_rresp;
    reg [31:0] s0_rdata;
    reg s0_bvalid, s0_rvalid, s0_rlast;
    wire s0_bready, s0_rready;

    // SLAVE 1
    wire [3:0] s1_awid, s1_arid;
    wire [31:0] s1_awaddr, s1_araddr;
    wire [7:0] s1_awlen, s1_arlen;
    wire [2:0] s1_awsize, s1_arsize;
    wire [1:0] s1_awburst, s1_arburst;
    wire s1_awlock, s1_arlock;
    wire [3:0] s1_awcache, s1_arcache;
    wire [2:0] s1_awprot, s1_arprot;
    wire [3:0] s1_awqos, s1_arqos;
    wire [3:0] s1_awregion, s1_arregion;
    wire s1_awvalid, s1_arvalid;
    reg s1_awready, s1_arready;

    wire [31:0] s1_wdata;
    wire [3:0] s1_wstrb;
    wire s1_wlast, s1_wvalid;
    reg s1_wready;

    reg [3:0] s1_bid, s1_rid;
    reg [1:0] s1_bresp, s1_rresp;
    reg [31:0] s1_rdata;
    reg s1_bvalid, s1_rvalid, s1_rlast;
    wire s1_bready, s1_rready;

    integer errors;
    integer tests_passed;
    integer tests;

    // CLOCK
    initial begin
        aclk = 0;
        forever #5 aclk = ~aclk;
    end

    // DUT
    axi4_crossbar_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),

        // MASTER 0 AW
        .m0_awid(m0_awid),
        .m0_awaddr(m0_awaddr),
        .m0_awlen(m0_awlen),
        .m0_awsize(m0_awsize),
        .m0_awburst(m0_awburst),
        .m0_awlock(m0_awlock),
        .m0_awcache(m0_awcache),
        .m0_awprot(m0_awprot),
        .m0_awqos(m0_awqos),
        .m0_awregion(m0_awregion),
        .m0_awvalid(m0_awvalid),
        .m0_awready(m0_awready),

        // MASTER 0 W/B
        .m0_wdata(m0_wdata),
        .m0_wstrb(m0_wstrb),
        .m0_wlast(m0_wlast),
        .m0_wvalid(m0_wvalid),
        .m0_wready(m0_wready),
        .m0_bid(m0_bid),
        .m0_bresp(m0_bresp),
        .m0_bvalid(m0_bvalid),
        .m0_bready(m0_bready),

        // MASTER 0 AR/R
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
        .m0_arready(m0_arready),
        .m0_rid(m0_rid),
        .m0_rdata(m0_rdata),
        .m0_rresp(m0_rresp),
        .m0_rlast(m0_rlast),
        .m0_rvalid(m0_rvalid),
        .m0_rready(m0_rready),

        // MASTER 1 AW
        .m1_awid(m1_awid),
        .m1_awaddr(m1_awaddr),
        .m1_awlen(m1_awlen),
        .m1_awsize(m1_awsize),
        .m1_awburst(m1_awburst),
        .m1_awlock(m1_awlock),
        .m1_awcache(m1_awcache),
        .m1_awprot(m1_awprot),
        .m1_awqos(m1_awqos),
        .m1_awregion(m1_awregion),
        .m1_awvalid(m1_awvalid),
        .m1_awready(m1_awready),

        // MASTER 1 W/B
        .m1_wdata(m1_wdata),
        .m1_wstrb(m1_wstrb),
        .m1_wlast(m1_wlast),
        .m1_wvalid(m1_wvalid),
        .m1_wready(m1_wready),
        .m1_bid(m1_bid),
        .m1_bresp(m1_bresp),
        .m1_bvalid(m1_bvalid),
        .m1_bready(m1_bready),

        // MASTER 1 AR/R
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
        .m1_arready(m1_arready),
        .m1_rid(m1_rid),
        .m1_rdata(m1_rdata),
        .m1_rresp(m1_rresp),
        .m1_rlast(m1_rlast),
        .m1_rvalid(m1_rvalid),
        .m1_rready(m1_rready),

        // SLAVE 0 AW/W/B
        .s0_awid(s0_awid),
        .s0_awaddr(s0_awaddr),
        .s0_awlen(s0_awlen),
        .s0_awsize(s0_awsize),
        .s0_awburst(s0_awburst),
        .s0_awlock(s0_awlock),
        .s0_awcache(s0_awcache),
        .s0_awprot(s0_awprot),
        .s0_awqos(s0_awqos),
        .s0_awregion(s0_awregion),
        .s0_awvalid(s0_awvalid),
        .s0_awready(s0_awready),
        .s0_wdata(s0_wdata),
        .s0_wstrb(s0_wstrb),
        .s0_wlast(s0_wlast),
        .s0_wvalid(s0_wvalid),
        .s0_wready(s0_wready),
        .s0_bid(s0_bid),
        .s0_bresp(s0_bresp),
        .s0_bvalid(s0_bvalid),
        .s0_bready(s0_bready),

        // SLAVE 0 AR/R
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
        .s0_rid(s0_rid),
        .s0_rdata(s0_rdata),
        .s0_rresp(s0_rresp),
        .s0_rlast(s0_rlast),
        .s0_rvalid(s0_rvalid),
        .s0_rready(s0_rready),

        // SLAVE 1 AW/W/B
        .s1_awid(s1_awid),
        .s1_awaddr(s1_awaddr),
        .s1_awlen(s1_awlen),
        .s1_awsize(s1_awsize),
        .s1_awburst(s1_awburst),
        .s1_awlock(s1_awlock),
        .s1_awcache(s1_awcache),
        .s1_awprot(s1_awprot),
        .s1_awqos(s1_awqos),
        .s1_awregion(s1_awregion),
        .s1_awvalid(s1_awvalid),
        .s1_awready(s1_awready),
        .s1_wdata(s1_wdata),
        .s1_wstrb(s1_wstrb),
        .s1_wlast(s1_wlast),
        .s1_wvalid(s1_wvalid),
        .s1_wready(s1_wready),
        .s1_bid(s1_bid),
        .s1_bresp(s1_bresp),
        .s1_bvalid(s1_bvalid),
        .s1_bready(s1_bready),

        // SLAVE 1 AR/R
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
        .s1_rid(s1_rid),
        .s1_rdata(s1_rdata),
        .s1_rresp(s1_rresp),
        .s1_rlast(s1_rlast),
        .s1_rvalid(s1_rvalid),
        .s1_rready(s1_rready)
    );
        // WRITE RESPONSE MODELS
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s0_bid <= 0;
            s0_bresp <= 0;
            s0_bvalid <= 0;
            s1_bid <= 0;
            s1_bresp <= 0;
            s1_bvalid <= 0;
        end else begin
            if (s0_awvalid && s0_awready)
                s0_bid <= s0_awid;

            if (s0_wvalid && s0_wready && s0_wlast) begin
                s0_bresp <= 2'b00;
                s0_bvalid <= 1;
            end

            if (s0_bvalid && s0_bready)
                s0_bvalid <= 0;

            if (s1_awvalid && s1_awready)
                s1_bid <= s1_awid;

            if (s1_wvalid && s1_wready && s1_wlast) begin
                s1_bresp <= 2'b00;
                s1_bvalid <= 1;
            end

            if (s1_bvalid && s1_bready)
                s1_bvalid <= 0;
        end
    end

    // READ RESPONSE MODELS
    reg [7:0] s0_rd_left, s1_rd_left;
    reg [31:0] s0_rd_data, s1_rd_data;
    reg s0_rd_active, s1_rd_active;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s0_rd_active <= 0;
            s0_rd_left <= 0;
            s0_rd_data <= 0;
            s0_rid <= 0;
            s0_rdata <= 0;
            s0_rresp <= 0;
            s0_rlast <= 0;
            s0_rvalid <= 0;
        end else begin
            if (s0_arvalid && s0_arready &&
                !s0_rd_active && !s0_rvalid) begin
                s0_rd_active <= 1;
                s0_rd_left <= s0_arlen;
                s0_rd_data <= s0_araddr;
                s0_rid <= s0_arid;
                s0_rdata <= s0_araddr;
                s0_rresp <= 2'b00;
                s0_rlast <= (s0_arlen == 0);
                s0_rvalid <= 1;
            end else if (s0_rvalid && s0_rready) begin
                if (s0_rd_left == 0) begin
                    s0_rvalid <= 0;
                    s0_rlast <= 0;
                    s0_rd_active <= 0;
                end else begin
                    s0_rd_left <= s0_rd_left - 1'b1;
                    s0_rd_data <= s0_rd_data + 4;
                    s0_rdata <= s0_rd_data + 4;
                    s0_rlast <= (s0_rd_left == 1);
                end
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s1_rd_active <= 0;
            s1_rd_left <= 0;
            s1_rd_data <= 0;
            s1_rid <= 0;
            s1_rdata <= 0;
            s1_rresp <= 0;
            s1_rlast <= 0;
            s1_rvalid <= 0;
        end else begin
            if (s1_arvalid && s1_arready &&
                !s1_rd_active && !s1_rvalid) begin
                s1_rd_active <= 1;
                s1_rd_left <= s1_arlen;
                s1_rd_data <= s1_araddr;
                s1_rid <= s1_arid;
                s1_rdata <= s1_araddr;
                s1_rresp <= 2'b00;
                s1_rlast <= (s1_arlen == 0);
                s1_rvalid <= 1;
            end else if (s1_rvalid && s1_rready) begin
                if (s1_rd_left == 0) begin
                    s1_rvalid <= 0;
                    s1_rlast <= 0;
                    s1_rd_active <= 0;
                end else begin
                    s1_rd_left <= s1_rd_left - 1'b1;
                    s1_rd_data <= s1_rd_data + 4;
                    s1_rdata <= s1_rd_data + 4;
                    s1_rlast <= (s1_rd_left == 1);
                end
            end
        end
    end

    // RESULT CHECKER
    task check_result;
        input condition;
        input [8*100-1:0] message;
        begin
            tests = tests + 1;
            if (condition)
                $display("PASS: %0s", message);
            else begin
                errors = errors + 1;
                $display("FAIL: %0s at %0t", message, $time);
            end
        end
    endtask

   
   
task do_write;
    input integer master;
    input [31:0] address;
    input [3:0] ident;
    input [1:0] expected_resp;

    reg aw_done;
    reg w_done;
    reg b_done;

    begin
        aw_done = 0;
        w_done  = 0;
        b_done  = 0;

        // ---------------------------------
        // MASTER 0 WRITE
        // ---------------------------------
        if (master == 0) begin

            // Address channel
            @(negedge aclk);
            m0_awaddr  = address;
            m0_awid    = ident;
            m0_awlen   = 0;
            m0_awvalid = 1;

            while (aw_done == 0) begin
                @(posedge aclk);
                if (m0_awready === 1'b1)
                    aw_done = 1;
            end

            @(negedge aclk);
            m0_awvalid = 0;

            // Write data channel
            m0_wdata  = 32'h12345678;
            m0_wstrb  = 4'hF;
            m0_wlast  = 1;
            m0_wvalid = 1;

            while (w_done == 0) begin
                @(posedge aclk);
                if (m0_wready === 1'b1)
                    w_done = 1;
            end

            @(negedge aclk);
            m0_wvalid = 0;
            m0_wlast  = 0;

            // Write response channel
            m0_bready = 1;

            while (b_done == 0) begin
                @(posedge aclk);
                if (m0_bvalid === 1'b1) begin
                    if (m0_bid !== ident || m0_bresp !== expected_resp) begin
                        $display("FAIL: M0 WRITE RESPONSE");
                        $display("Expected BID=%h BRESP=%b",
                                 ident, expected_resp);
                        $display("Received BID=%h BRESP=%b",
                                 m0_bid, m0_bresp);
                        errors = errors + 1;
                    end
                    else begin
                        $display("PASS: M0 WRITE");
                        tests_passed = tests_passed + 1;
                    end
                    b_done = 1;
                end
            end

            @(negedge aclk);
            m0_bready = 0;
        end

        // ---------------------------------
        // MASTER 1 WRITE
        // ---------------------------------
        else begin

            // Address channel
            @(negedge aclk);
            m1_awaddr  = address;
            m1_awid    = ident;
            m1_awlen   = 0;
            m1_awvalid = 1;

            while (aw_done == 0) begin
                @(posedge aclk);
                if (m1_awready === 1'b1)
                    aw_done = 1;
            end

            @(negedge aclk);
            m1_awvalid = 0;

            // Write data channel
            m1_wdata  = 32'h87654321;
            m1_wstrb  = 4'hF;
            m1_wlast  = 1;
            m1_wvalid = 1;

            while (w_done == 0) begin
                @(posedge aclk);
                if (m1_wready === 1'b1)
                    w_done = 1;
            end

            @(negedge aclk);
            m1_wvalid = 0;
            m1_wlast  = 0;

            // Write response channel
            m1_bready = 1;

            while (b_done == 0) begin
                @(posedge aclk);
                if (m1_bvalid === 1'b1) begin
                    if (m1_bid !== ident || m1_bresp !== expected_resp) begin
                        $display("FAIL: M1 WRITE RESPONSE");
                        $display("Expected BID=%h BRESP=%b",
                                 ident, expected_resp);
                        $display("Received BID=%h BRESP=%b",
                                 m1_bid, m1_bresp);
                        errors = errors + 1;
                    end
                    else begin
                        $display("PASS: M1 WRITE");
                        tests_passed = tests_passed + 1;
                    end
                    b_done = 1;
                end
            end

            @(negedge aclk);
            m1_bready = 0;
        end
    end
endtask



  
task do_read;
    input integer master;
    input [31:0] address;
    input [3:0] ident;
    input [7:0] length;
    input [1:0] expected_resp;

    integer beats;
    reg ar_done;

    begin
        beats = 0;
        ar_done = 0;

        // ---------------------------------
        // MASTER 0 READ
        // ---------------------------------
        if (master == 0) begin

            @(negedge aclk);
            m0_araddr  = address;
            m0_arid    = ident;
            m0_arlen   = length;
            m0_arvalid = 1;

            // Wait for actual AR handshake
            while (ar_done == 0) begin
                @(posedge aclk);
                if (m0_arready === 1'b1)
                    ar_done = 1;
            end

            @(negedge aclk);
            m0_arvalid = 0;
            m0_rready  = 1;

            begin : M0_READ_LOOP
                forever begin
                    @(posedge aclk);

                    if (m0_rvalid === 1'b1 &&
                        m0_rready === 1'b1) begin

                        beats = beats + 1;

                        check_result(m0_rid == ident,
                                     "M0 read ID preserved");

                        check_result(m0_rresp == expected_resp,
                                     "M0 read response correct");

                        if (expected_resp == 2'b11)
                            check_result(m0_rdata == 0,
                                         "M0 DECERR data zero");

                        if (m0_rlast === 1'b1)
                            disable M0_READ_LOOP;
                    end
                end
            end

            check_result(beats == (length + 1),
                         "M0 read beat count correct");

            @(negedge aclk);
            m0_rready = 0;
        end

        // ---------------------------------
        // MASTER 1 READ
        // ---------------------------------
        else begin

            @(negedge aclk);
            m1_araddr  = address;
            m1_arid    = ident;
            m1_arlen   = length;
            m1_arvalid = 1;

            // Wait for actual AR handshake
            while (ar_done == 0) begin
                @(posedge aclk);
                if (m1_arready === 1'b1)
                    ar_done = 1;
            end

            @(negedge aclk);
            m1_arvalid = 0;
            m1_rready  = 1;

            begin : M1_READ_LOOP
                forever begin
                    @(posedge aclk);

                    if (m1_rvalid === 1'b1 &&
                        m1_rready === 1'b1) begin

                        beats = beats + 1;

                        check_result(m1_rid == ident,
                                     "M1 read ID preserved");

                        check_result(m1_rresp == expected_resp,
                                     "M1 read response correct");

                        if (expected_resp == 2'b11)
                            check_result(m1_rdata == 0,
                                         "M1 DECERR data zero");

                        if (m1_rlast === 1'b1)
                            disable M1_READ_LOOP;
                    end
                end
            end

            check_result(beats == (length + 1),
                         "M1 read beat count correct");

            @(negedge aclk);
            m1_rready = 0;
        end
    end
endtask

        initial begin

        errors = 0;
        tests_passed = 0;
        tests = 0;

        aresetn = 0;
        arb_policy = 2'b00;

        // MASTER 0 WRITE INITIALIZATION
        m0_awid = 0;
        m0_awaddr = 0;
        m0_awlen = 0;
        m0_awsize = 3'b010;
        m0_awburst = 2'b01;
        m0_awlock = 0;
        m0_awcache = 0;
        m0_awprot = 0;
        m0_awqos = 0;
        m0_awregion = 0;
        m0_awvalid = 0;

        m0_wdata = 0;
        m0_wstrb = 0;
        m0_wlast = 0;
        m0_wvalid = 0;
        m0_bready = 0;

        // MASTER 0 READ INITIALIZATION
        m0_arid = 0;
        m0_araddr = 0;
        m0_arlen = 0;
        m0_arsize = 3'b010;
        m0_arburst = 2'b01;
        m0_arlock = 0;
        m0_arcache = 0;
        m0_arprot = 0;
        m0_arqos = 0;
        m0_arregion = 0;
        m0_arvalid = 0;
        m0_rready = 0;

        // MASTER 1 WRITE INITIALIZATION
        m1_awid = 0;
        m1_awaddr = 0;
        m1_awlen = 0;
        m1_awsize = 3'b010;
        m1_awburst = 2'b01;
        m1_awlock = 0;
        m1_awcache = 0;
        m1_awprot = 0;
        m1_awqos = 0;
        m1_awregion = 0;
        m1_awvalid = 0;

        m1_wdata = 0;
        m1_wstrb = 0;
        m1_wlast = 0;
        m1_wvalid = 0;
        m1_bready = 0;

        // MASTER 1 READ INITIALIZATION
        m1_arid = 0;
        m1_araddr = 0;
        m1_arlen = 0;
        m1_arsize = 3'b010;
        m1_arburst = 2'b01;
        m1_arlock = 0;
        m1_arcache = 0;
        m1_arprot = 0;
        m1_arqos = 0;
        m1_arregion = 0;
        m1_arvalid = 0;
        m1_rready = 0;

        // SLAVE READY SIGNALS
        s0_awready = 1;
        s0_wready = 1;
        s0_arready = 1;

        s1_awready = 1;
        s1_wready = 1;
        s1_arready = 1;

        // RESET
        repeat (5) @(posedge aclk);
        @(negedge aclk);
        aresetn = 1;

        repeat (2) @(posedge aclk);

        $display("");
        $display("========================================");
        $display(" AXI4 CROSSBAR TOP-LEVEL TEST START");
        $display("========================================");

        // TEST 1: M0 writes to Slave 0
        do_write(0, 32'h00000020, 4'h1, 2'b00);

        // TEST 2: M1 writes to Slave 1
        do_write(1, 32'h00010020, 4'h2, 2'b00);

        // TEST 3: M0 reads from Slave 1
        do_read(0, 32'h00010040, 4'h3, 0, 2'b00);

        // TEST 4: M1 reads from Slave 0
        do_read(1, 32'h00000040, 4'h4, 0, 2'b00);

        // TEST 5: M0 unmapped read -> DECERR
        do_read(0, 32'h00020000, 4'h5, 2, 2'b11);

        // TEST 6: M1 unmapped write -> DECERR
        do_write(1, 32'h00020004, 4'h6, 2'b11);

        // SUMMARY
        $display("");
        $display("========================================");
        $display(" TEST SUMMARY");
        $display("========================================");
        $display("Checks run : %0d", tests);
        $display("Failures   : %0d", errors);

        if (errors == 0)
            $display("ALL COMPLETED TESTS PASSED");
        else
            $display("TESTS FAILED");

        $finish;
    end

    // WATCHDOG
    initial begin
        #200000;
        $display("ERROR: TESTBENCH TIMEOUT");
        $finish;
    end
// DEBUG MONITOR
always @(posedge aclk) begin
    if (aresetn) begin

        if (m0_awvalid || m1_awvalid) begin
            $display(
                "AW DEBUG @ %0t | M0: VALID=%b READY=%b | M1: VALID=%b READY=%b",
                $time,
                m0_awvalid, m0_awready,
                m1_awvalid, m1_awready
            );

            $display(
                "SLAVE AW | S0: VALID=%b READY=%b | S1: VALID=%b READY=%b",
                s0_awvalid, s0_awready,
                s1_awvalid, s1_awready
            );
        end

        if (m0_wvalid || m1_wvalid) begin
            $display(
                "W DEBUG @ %0t | M0: VALID=%b READY=%b | M1: VALID=%b READY=%b",
                $time,
                m0_wvalid, m0_wready,
                m1_wvalid, m1_wready
            );
        end

    end
end
// MASTER 0 TRACKER DEBUG
always @(posedge aclk) begin
    if (aresetn) begin
        $display(
            "TRACKER DEBUG @ %0t | AWVALID=%b AWREADY=%b | AW_ACCEPT=%b | WRITE_BUSY=%b | WRITE_AVAILABLE=%b",
            $time,
            m0_awvalid,
            m0_awready,
            dut.m0_aw_accept,
            dut.U_MASTER_TRACKER.m0_write_busy,
            dut.m0_write_available
        );
    end
end
endmodule