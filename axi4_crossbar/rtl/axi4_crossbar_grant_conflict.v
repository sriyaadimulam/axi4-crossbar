
`timescale 1ns / 1ps

module axi4_crossbar_grant_conflict(

    // Arbitration grants
    input wire [1:0] s0_grant,
    input wire [1:0] s1_grant,

    // Arbitration enables
    input wire s0_enable,
    input wire s1_enable,

    // Final grants after conflict resolution
    output wire [1:0] s0_final_grant,
    output wire [1:0] s1_final_grant,

    // Final enables
    output wire s0_final_enable,
    output wire s1_final_enable,

    // Conflict indication
    output wire m0_conflict,
    output wire m1_conflict

);

    // S0 retains its grant.
    assign s0_final_grant = s0_grant;
    assign s0_final_enable = s0_enable;

    // M0 conflict: both slaves selected M0.
    assign m0_conflict =
        s0_enable && s1_enable &&
        (s0_grant == 2'b01) &&
        (s1_grant == 2'b01);

    // M1 conflict: both slaves selected M1.
    assign m1_conflict =
        s0_enable && s1_enable &&
        (s0_grant == 2'b10) &&
        (s1_grant == 2'b10);

    // Suppress S1 grant during same-master conflict.
    assign s1_final_enable =
        s1_enable && !(m0_conflict || m1_conflict);

    assign s1_final_grant =
        s1_final_enable ? s1_grant : 2'b00;

endmodule
