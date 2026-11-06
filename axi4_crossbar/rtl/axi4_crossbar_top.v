
`timescale 1ns / 1ps

module axi4_crossbar_top #(
    parameter ADDR_WIDTH    = 32,
    parameter DATA_WIDTH    = 32,
    parameter ID_WIDTH      = 4,
    parameter MAX_BURST_LEN = 16,
    parameter AGE_WIDTH     = 32,
    parameter SERVICE_WIDTH = 32,
    parameter ARB_WEIGHT    = 2
)(
    // =====================================================
    // CLOCK AND RESET
    // =====================================================
    input wire aclk,
    input wire aresetn,

    // Arbitration policy:
    // 00 = Fixed priority
    // 01 = Round robin
    // 10 = Burst-aware age-based
    input wire [1:0] arb_policy,


    // =====================================================
    // MASTER 0 INTERFACE
    // =====================================================

    // Write Address (AW)
    input  wire [ID_WIDTH-1:0]   m0_awid,
    input  wire [ADDR_WIDTH-1:0] m0_awaddr,
    input  wire [7:0]            m0_awlen,
    input  wire [2:0]            m0_awsize,
    input  wire [1:0]            m0_awburst,
    input  wire                  m0_awlock,
    input  wire [3:0]            m0_awcache,
    input  wire [2:0]            m0_awprot,
    input  wire [3:0]            m0_awqos,
    input  wire [3:0]            m0_awregion,
    input  wire                  m0_awvalid,
    output wire                  m0_awready,

    // Write Data (W)
    input  wire [DATA_WIDTH-1:0] m0_wdata,
    input  wire [DATA_WIDTH/8-1:0] m0_wstrb,
    input  wire                  m0_wlast,
    input  wire                  m0_wvalid,
    output wire                  m0_wready,

    // Write Response (B)
    output wire [ID_WIDTH-1:0]   m0_bid,
    output wire [1:0]            m0_bresp,
    output wire                  m0_bvalid,
    input  wire                  m0_bready,

    // Read Address (AR)
    input  wire [ID_WIDTH-1:0]   m0_arid,
    input  wire [ADDR_WIDTH-1:0] m0_araddr,
    input  wire [7:0]            m0_arlen,
    input  wire [2:0]            m0_arsize,
    input  wire [1:0]            m0_arburst,
    input  wire                  m0_arlock,
    input  wire [3:0]            m0_arcache,
    input  wire [2:0]            m0_arprot,
    input  wire [3:0]            m0_arqos,
    input  wire [3:0]            m0_arregion,
    input  wire                  m0_arvalid,
    output wire                  m0_arready,

    // Read Data (R)
    output wire [ID_WIDTH-1:0]   m0_rid,
    output wire [DATA_WIDTH-1:0] m0_rdata,
    output wire [1:0]            m0_rresp,
    output wire                  m0_rlast,
    output wire                  m0_rvalid,
    input  wire                  m0_rready,


    // =====================================================
    // MASTER 1 INTERFACE
    // =====================================================

    // Write Address (AW)
    input  wire [ID_WIDTH-1:0]   m1_awid,
    input  wire [ADDR_WIDTH-1:0] m1_awaddr,
    input  wire [7:0]            m1_awlen,
    input  wire [2:0]            m1_awsize,
    input  wire [1:0]            m1_awburst,
    input  wire                  m1_awlock,
    input  wire [3:0]            m1_awcache,
    input  wire [2:0]            m1_awprot,
    input  wire [3:0]            m1_awqos,
    input  wire [3:0]            m1_awregion,
    input  wire                  m1_awvalid,
    output wire                  m1_awready,

    // Write Data (W)
    input  wire [DATA_WIDTH-1:0] m1_wdata,
    input  wire [DATA_WIDTH/8-1:0] m1_wstrb,
    input  wire                  m1_wlast,
    input  wire                  m1_wvalid,
    output wire                  m1_wready,

    // Write Response (B)
    output wire [ID_WIDTH-1:0]   m1_bid,
    output wire [1:0]            m1_bresp,
    output wire                  m1_bvalid,
    input  wire                  m1_bready,

    // Read Address (AR)
    input  wire [ID_WIDTH-1:0]   m1_arid,
    input  wire [ADDR_WIDTH-1:0] m1_araddr,
    input  wire [7:0]            m1_arlen,
    input  wire [2:0]            m1_arsize,
    input  wire [1:0]            m1_arburst,
    input  wire                  m1_arlock,
    input  wire [3:0]            m1_arcache,
    input  wire [2:0]            m1_arprot,
    input  wire [3:0]            m1_arqos,
    input  wire [3:0]            m1_arregion,
    input  wire                  m1_arvalid,
    output wire                  m1_arready,

    // Read Data (R)
    output wire [ID_WIDTH-1:0]   m1_rid,
    output wire [DATA_WIDTH-1:0] m1_rdata,
    output wire [1:0]            m1_rresp,
    output wire                  m1_rlast,
    output wire                  m1_rvalid,
    input  wire                  m1_rready,


    // =====================================================
    // SLAVE 0 INTERFACE
    // =====================================================

    // Write Address (AW)
    output wire [ID_WIDTH-1:0]   s0_awid,
    output wire [ADDR_WIDTH-1:0] s0_awaddr,
    output wire [7:0]            s0_awlen,
    output wire [2:0]            s0_awsize,
    output wire [1:0]            s0_awburst,
    output wire                  s0_awlock,
    output wire [3:0]            s0_awcache,
    output wire [2:0]            s0_awprot,
    output wire [3:0]            s0_awqos,
    output wire [3:0]            s0_awregion,
    output wire                  s0_awvalid,
    input  wire                  s0_awready,

    // Write Data (W)
    output wire [DATA_WIDTH-1:0] s0_wdata,
    output wire [DATA_WIDTH/8-1:0] s0_wstrb,
    output wire                  s0_wlast,
    output wire                  s0_wvalid,
    input  wire                  s0_wready,

    // Write Response (B)
    input  wire [ID_WIDTH-1:0]   s0_bid,
    input  wire [1:0]            s0_bresp,
    input  wire                  s0_bvalid,
    output wire                  s0_bready,

    // Read Address (AR)
    output wire [ID_WIDTH-1:0]   s0_arid,
    output wire [ADDR_WIDTH-1:0] s0_araddr,
    output wire [7:0]            s0_arlen,
    output wire [2:0]            s0_arsize,
    output wire [1:0]            s0_arburst,
    output wire                  s0_arlock,
    output wire [3:0]            s0_arcache,
    output wire [2:0]            s0_arprot,
    output wire [3:0]            s0_arqos,
    output wire [3:0]            s0_arregion,
    output wire                  s0_arvalid,
    input  wire                  s0_arready,

    // Read Data (R)
    input  wire [ID_WIDTH-1:0]   s0_rid,
    input  wire [DATA_WIDTH-1:0] s0_rdata,
    input  wire [1:0]            s0_rresp,
    input  wire                  s0_rlast,
    input  wire                  s0_rvalid,
    output wire                  s0_rready,


    // =====================================================
    // SLAVE 1 INTERFACE
    // =====================================================

    // Write Address (AW)
    output wire [ID_WIDTH-1:0]   s1_awid,
    output wire [ADDR_WIDTH-1:0] s1_awaddr,
    output wire [7:0]            s1_awlen,
    output wire [2:0]            s1_awsize,
    output wire [1:0]            s1_awburst,
    output wire                  s1_awlock,
    output wire [3:0]            s1_awcache,
    output wire [2:0]            s1_awprot,
    output wire [3:0]            s1_awqos,
    output wire [3:0]            s1_awregion,
    output wire                  s1_awvalid,
    input  wire                  s1_awready,

    // Write Data (W)
    output wire [DATA_WIDTH-1:0] s1_wdata,
    output wire [DATA_WIDTH/8-1:0] s1_wstrb,
    output wire                  s1_wlast,
    output wire                  s1_wvalid,
    input  wire                  s1_wready,

    // Write Response (B)
    input  wire [ID_WIDTH-1:0]   s1_bid,
    input  wire [1:0]            s1_bresp,
    input  wire                  s1_bvalid,
    output wire                  s1_bready,

    // Read Address (AR)
    output wire [ID_WIDTH-1:0]   s1_arid,
    output wire [ADDR_WIDTH-1:0] s1_araddr,
    output wire [7:0]            s1_arlen,
    output wire [2:0]            s1_arsize,
    output wire [1:0]            s1_arburst,
    output wire                  s1_arlock,
    output wire [3:0]            s1_arcache,
    output wire [2:0]            s1_arprot,
    output wire [3:0]            s1_arqos,
    output wire [3:0]            s1_arregion,
    output wire                  s1_arvalid,
    input  wire                  s1_arready,

    // Read Data (R)
    input  wire [ID_WIDTH-1:0]   s1_rid,
    input  wire [DATA_WIDTH-1:0] s1_rdata,
    input  wire [1:0]            s1_rresp,
    input  wire                  s1_rlast,
    input  wire                  s1_rvalid,
    output wire                  s1_rready

);

    // =====================================================
    // INTERNAL IMPLEMENTATION
    // To be connected in subsequent development milestones
    // =====================================================

endmodule
