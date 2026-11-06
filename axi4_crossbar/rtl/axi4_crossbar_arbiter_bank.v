
`timescale 1ns / 1ps

module axi4_crossbar_arbiter_bank (

    input wire aclk,
    input wire aresetn,

    input wire [1:0] arb_policy,

    // --------------------------------
    // Slave 0 Read Arbitration
    // --------------------------------
    input wire [1:0] s0_rd_req,
    input wire s0_rd_enable,
    input wire s0_rd_grant_accept,
    input wire s0_rd_service_valid,
    input wire s0_rd_service_master,
    input wire s0_rd_epoch_clear,
    output wire [1:0] s0_rd_grant,

    // --------------------------------
    // Slave 0 Write Arbitration
    // --------------------------------
    input wire [1:0] s0_wr_req,
    input wire s0_wr_enable,
    input wire s0_wr_grant_accept,
    input wire s0_wr_service_valid,
    input wire s0_wr_service_master,
    input wire s0_wr_epoch_clear,
    output wire [1:0] s0_wr_grant,

    // --------------------------------
    // Slave 1 Read Arbitration
    // --------------------------------
    input wire [1:0] s1_rd_req,
    input wire s1_rd_enable,
    input wire s1_rd_grant_accept,
    input wire s1_rd_service_valid,
    input wire s1_rd_service_master,
    input wire s1_rd_epoch_clear,
    output wire [1:0] s1_rd_grant,

    // --------------------------------
    // Slave 1 Write Arbitration
    // --------------------------------
    input wire [1:0] s1_wr_req,
    input wire s1_wr_enable,
    input wire s1_wr_grant_accept,
    input wire s1_wr_service_valid,
    input wire s1_wr_service_master,
    input wire s1_wr_epoch_clear,
    output wire [1:0] s1_wr_grant

);

    // Slave 0 Read
    arbitration_policy_unit U_S0_READ (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),
        .req(s0_rd_req),
        .arb_enable(s0_rd_enable),
        .grant_accept(s0_rd_grant_accept),
        .service_valid(s0_rd_service_valid),
        .service_master(s0_rd_service_master),
        .epoch_clear(s0_rd_epoch_clear),
        .grant(s0_rd_grant)
    );

    // Slave 0 Write
    arbitration_policy_unit U_S0_WRITE (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),
        .req(s0_wr_req),
        .arb_enable(s0_wr_enable),
        .grant_accept(s0_wr_grant_accept),
        .service_valid(s0_wr_service_valid),
        .service_master(s0_wr_service_master),
        .epoch_clear(s0_wr_epoch_clear),
        .grant(s0_wr_grant)
    );

    // Slave 1 Read
    arbitration_policy_unit U_S1_READ (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),
        .req(s1_rd_req),
        .arb_enable(s1_rd_enable),
        .grant_accept(s1_rd_grant_accept),
        .service_valid(s1_rd_service_valid),
        .service_master(s1_rd_service_master),
        .epoch_clear(s1_rd_epoch_clear),
        .grant(s1_rd_grant)
    );

    // Slave 1 Write
    arbitration_policy_unit U_S1_WRITE (
        .aclk(aclk),
        .aresetn(aresetn),
        .arb_policy(arb_policy),
        .req(s1_wr_req),
        .arb_enable(s1_wr_enable),
        .grant_accept(s1_wr_grant_accept),
        .service_valid(s1_wr_service_valid),
        .service_master(s1_wr_service_master),
        .epoch_clear(s1_wr_epoch_clear),
        .grant(s1_wr_grant)
    );

endmodule
