
`timescale 1ns / 1ps

module axi4_simple_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter ID_WIDTH   = 4,
    parameter BASE_ADDR  = 32'h00000000,
    parameter MEM_WORDS  = 8196
)(
    input wire aclk,
    input wire aresetn,

    input wire [ID_WIDTH-1:0] s_awid,
    input wire [ADDR_WIDTH-1:0] s_awaddr,
    input wire [7:0] s_awlen,
    input wire [2:0] s_awsize,
    input wire [1:0] s_awburst,
    input wire s_awvalid,
    output reg s_awready,

    input wire [DATA_WIDTH-1:0] s_wdata,
    input wire [DATA_WIDTH/8-1:0] s_wstrb,
    input wire s_wlast,
    input wire s_wvalid,
    output reg s_wready,

    output reg [ID_WIDTH-1:0] s_bid,
    output reg [1:0] s_bresp,
    output reg s_bvalid,
    input wire s_bready,

    input wire [ID_WIDTH-1:0] s_arid,
    input wire [ADDR_WIDTH-1:0] s_araddr,
    input wire [7:0] s_arlen,
    input wire [2:0] s_arsize,
    input wire [1:0] s_arburst,
    input wire s_arvalid,
    output reg s_arready,

    output reg [ID_WIDTH-1:0] s_rid,
    output reg [DATA_WIDTH-1:0] s_rdata,
    output reg [1:0] s_rresp,
    output reg s_rlast,
    output reg s_rvalid,
    input wire s_rready
);

    localparam ADDR_BITS = $clog2(MEM_WORDS);

    // ------------------------------------------------
    // BRAM: independent write and synchronous read ports
    // ------------------------------------------------

    reg [ADDR_BITS-1:0] mem_wr_addr;
    reg [ADDR_BITS-1:0] mem_rd_addr;
    reg [DATA_WIDTH-1:0] mem_rd_data;
    reg [DATA_WIDTH/8-1:0] mem_we;
    reg mem_rd_en;

    wire [DATA_WIDTH-1:0] bram_dout;

    xpm_memory_sdpram #(
        .ADDR_WIDTH_A(ADDR_BITS),
        .ADDR_WIDTH_B(ADDR_BITS),
        .AUTO_SLEEP_TIME(0),
        .BYTE_WRITE_WIDTH_A(8),
        .CASCADE_HEIGHT(0),
        .CLOCKING_MODE("common_clock"),
        .ECC_MODE("no_ecc"),
        .MEMORY_INIT_FILE("none"),
        .MEMORY_INIT_PARAM("0"),
        .MEMORY_OPTIMIZATION("true"),
        .MEMORY_PRIMITIVE("block"),
        .MEMORY_SIZE(MEM_WORDS * DATA_WIDTH),
        .MESSAGE_CONTROL(0),
        .READ_DATA_WIDTH_B(DATA_WIDTH),
        .READ_LATENCY_B(1),
        .READ_RESET_VALUE_B("0"),
        .RST_MODE_B("SYNC"),
        .SIM_ASSERT_CHK(0),
        .USE_EMBEDDED_CONSTRAINT(0),
        .USE_MEM_INIT(0),
        .WAKEUP_TIME("disable_sleep"),
        .WRITE_DATA_WIDTH_A(DATA_WIDTH),
        .WRITE_MODE_B("read_first")
    ) BRAM_INST (
        .clka(aclk),
        .clkb(aclk),
        .ena(1'b1),
        .enb(mem_rd_en),
        .wea(mem_we),
        .addra(mem_wr_addr),
        .addrb(mem_rd_addr),
        .dina(s_wdata),
        .doutb(bram_dout),
        .regceb(1'b1),
        .rstb(1'b0),
        .sleep(1'b0),
        .injectdbiterra(1'b0),
        .injectsbiterra(1'b0)
    );

    // ------------------------------------------------
    // Address progression
    // ------------------------------------------------

    function [ADDR_WIDTH-1:0] next_address;
        input [ADDR_WIDTH-1:0] current_addr;
        input [ADDR_WIDTH-1:0] start_addr;
        input [7:0] burst_len;
        input [2:0] transfer_size;
        input [1:0] burst_type;

        reg [ADDR_WIDTH-1:0] bytes_per_beat;
        reg [ADDR_WIDTH-1:0] burst_bytes;
        reg [ADDR_WIDTH-1:0] wrap_base;

        begin
            bytes_per_beat = (1 << transfer_size);

            if (burst_type == 2'b00)
                next_address = current_addr;
            else if (burst_type == 2'b10) begin
                burst_bytes = (burst_len + 1) * bytes_per_beat;
                wrap_base = start_addr & ~(burst_bytes - 1);
                next_address = current_addr + bytes_per_beat;

                if (next_address >= wrap_base + burst_bytes)
                    next_address = wrap_base;
            end
            else
                next_address = current_addr + bytes_per_beat;
        end
    endfunction

    // ------------------------------------------------
    // Write control
    // ------------------------------------------------

    reg write_active;
    reg [ADDR_WIDTH-1:0] write_addr;
    reg [ADDR_WIDTH-1:0] write_start_addr;
    reg [ID_WIDTH-1:0] write_id;
    reg [7:0] write_len;
    reg [7:0] write_count;
    reg [2:0] write_size;
    reg [1:0] write_burst;
    reg [1:0] write_response;

    wire [ADDR_WIDTH-1:0] write_offset =
        write_addr - BASE_ADDR;

    wire [ADDR_BITS-1:0] write_word_index =
        write_offset[ADDR_BITS+1:2];

    // ------------------------------------------------
    // Read control
    // ------------------------------------------------

    reg read_active;
    reg read_pending;
    reg [ADDR_WIDTH-1:0] read_addr;
    reg [ADDR_WIDTH-1:0] read_start_addr;
    reg [ID_WIDTH-1:0] read_id;
    reg [7:0] read_len;
    reg [7:0] read_count;
    reg [2:0] read_size;
    reg [1:0] read_burst;
    reg [1:0] read_response;

    wire [ADDR_WIDTH-1:0] read_offset =
        read_addr - BASE_ADDR;

    wire [ADDR_BITS-1:0] read_word_index =
        read_offset[ADDR_BITS+1:2];

    // ------------------------------------------------
    // BRAM read/write controls
    // ------------------------------------------------

    always @(*) begin
        mem_we = 0;
        mem_wr_addr = 0;

        if (aresetn && s_wvalid && s_wready && write_active &&
            write_addr >= BASE_ADDR &&
            write_addr < BASE_ADDR + MEM_WORDS*4 &&
            write_size <= 2) begin

            mem_we = s_wstrb;
            mem_wr_addr = write_word_index;
        end
    end

    always @(*) begin
        mem_rd_en = 0;
        mem_rd_addr = 0;

        if (aresetn && s_arvalid && s_arready &&
            s_araddr >= BASE_ADDR &&
            s_araddr < BASE_ADDR + MEM_WORDS*4 &&
            s_arsize <= 2) begin

            mem_rd_en = 1;
            mem_rd_addr = (s_araddr - BASE_ADDR) >> 2;
        end
        else if (aresetn && s_rvalid && s_rready &&
                 read_count < read_len &&
                 read_addr >= BASE_ADDR &&
                 read_addr < BASE_ADDR + MEM_WORDS*4) begin

            mem_rd_en = 1;
            mem_rd_addr =
                (next_address(read_addr, read_start_addr,
                              read_len, read_size, read_burst)
                 - BASE_ADDR) >> 2;
        end
    end

    // ------------------------------------------------
    // AXI control
    // ------------------------------------------------

    always @(posedge aclk) begin

        if (!aresetn) begin

            write_active <= 0;
            write_addr <= 0;
            write_start_addr <= 0;
            write_id <= 0;
            write_len <= 0;
            write_count <= 0;
            write_size <= 0;
            write_burst <= 0;
            write_response <= 0;

            s_awready <= 1;
            s_wready <= 0;

            s_bid <= 0;
            s_bresp <= 0;
            s_bvalid <= 0;

            read_active <= 0;
            read_pending <= 0;
            read_addr <= 0;
            read_start_addr <= 0;
            read_id <= 0;
            read_len <= 0;
            read_count <= 0;
            read_size <= 0;
            read_burst <= 0;
            read_response <= 0;

            s_arready <= 1;

            s_rid <= 0;
            s_rdata <= 0;
            s_rresp <= 0;
            s_rlast <= 0;
            s_rvalid <= 0;

        end else begin

            // WRITE ADDRESS
            if (s_awvalid && s_awready) begin

                write_active <= 1;
                write_addr <= s_awaddr;
                write_start_addr <= s_awaddr;
                write_id <= s_awid;
                write_len <= s_awlen;
                write_count <= 0;
                write_size <= s_awsize;
                write_burst <= s_awburst;

                write_response <= 0;

                s_awready <= 0;
                s_wready <= 1;

                if (s_awlen > 15 || s_awsize > 2 ||
                    s_awburst == 2'b11 ||
                    s_awaddr < BASE_ADDR ||
                    s_awaddr >= BASE_ADDR + MEM_WORDS*4)
                    write_response <= 2'b10;

                if (s_awburst == 2'b10 &&
                    !(s_awlen == 1 || s_awlen == 3 ||
                      s_awlen == 7 || s_awlen == 15))
                    write_response <= 2'b10;
            end

            // WRITE DATA
            if (s_wvalid && s_wready && write_active) begin

                if (write_addr < BASE_ADDR ||
                    write_addr >= BASE_ADDR + MEM_WORDS*4 ||
                    write_size > 2)
                    write_response <= 2'b10;

                if (s_wlast != (write_count == write_len))
                    write_response <= 2'b10;

                if (write_count == write_len) begin

                    write_active <= 0;
                    s_wready <= 0;

                    s_bid <= write_id;

                    // Check the current beat's WLAST directly.
                    // This avoids reading the previous write_response
                    // value on the final beat.
                    if (write_response == 2'b10 ||
                        s_wlast != (write_count == write_len) ||
                        write_addr < BASE_ADDR ||
                        write_addr >= BASE_ADDR + MEM_WORDS*4 ||
                        write_size > 2)
                        s_bresp <= 2'b10;
                    else
                        s_bresp <= 2'b00;

                    s_bvalid <= 1;

                end else begin

                    write_count <= write_count + 1'b1;

                    write_addr <= next_address(
                        write_addr, write_start_addr,
                        write_len, write_size, write_burst
                    );

                end
            end

            // WRITE RESPONSE
            if (s_bvalid && s_bready) begin
                s_bvalid <= 0;
                s_awready <= 1;
            end

            // READ ADDRESS
            if (s_arvalid && s_arready) begin

                read_active <= 1;
                read_pending <= 1;

                read_addr <= s_araddr;
                read_start_addr <= s_araddr;
                read_id <= s_arid;
                read_len <= s_arlen;
                read_count <= 0;
                read_size <= s_arsize;
                read_burst <= s_arburst;

                s_rid <= s_arid;
                s_arready <= 0;
                s_rvalid <= 0;

                read_response <= 0;

                if (s_araddr < BASE_ADDR ||
                    s_araddr >= BASE_ADDR + MEM_WORDS*4 ||
                    s_arsize > 2 || s_arlen > 15 ||
                    s_arburst == 2'b11)
                    read_response <= 2'b10;

                if (s_arburst == 2'b10 &&
                    !(s_arlen == 1 || s_arlen == 3 ||
                      s_arlen == 7 || s_arlen == 15))
                    read_response <= 2'b10;
            end

            // CAPTURE SYNCHRONOUS BRAM READ
            if (read_pending) begin

                read_pending <= 0;
                s_rvalid <= 1;
                s_rlast <= (read_count == read_len);

                if (read_response == 2'b10)
                    s_rresp <= 2'b10;
                else begin
                    s_rdata <= bram_dout;
                    s_rresp <= 2'b00;
                end

                if (read_response == 2'b10)
                    s_rdata <= 0;
            end

            // READ DATA HANDSHAKE
            if (s_rvalid && s_rready) begin

                if (read_count == read_len) begin

                    s_rvalid <= 0;
                    s_rlast <= 0;
                    read_active <= 0;
                    s_arready <= 1;

                end else begin

                    read_count <= read_count + 1'b1;

                    read_addr <= next_address(
                        read_addr, read_start_addr,
                        read_len, read_size, read_burst
                    );

                    read_pending <= 1;
                    s_rvalid <= 0;
                end
            end
        end
    end

endmodule
