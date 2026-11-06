
`timescale 1ns / 1ps

module address_decoder #(
    parameter ADDR_WIDTH = 32,

    parameter [ADDR_WIDTH-1:0] S0_BASE_ADDR = 32'h00000000,
    parameter [ADDR_WIDTH-1:0] S0_ADDR_MASK = 32'hFFFF0000,

    parameter [ADDR_WIDTH-1:0] S1_BASE_ADDR = 32'h00010000,
    parameter [ADDR_WIDTH-1:0] S1_ADDR_MASK = 32'hFFFF0000
)(
    input wire [ADDR_WIDTH-1:0] addr,

    output wire s0_sel,
    output wire s1_sel,
    output wire decode_error
);

    // Slave 0: 0x00000000 - 0x0000FFFF
    assign s0_sel =
        ((addr & S0_ADDR_MASK) == (S0_BASE_ADDR & S0_ADDR_MASK));

    // Slave 1: 0x00010000 - 0x0001FFFF
    assign s1_sel =
        ((addr & S1_ADDR_MASK) == (S1_BASE_ADDR & S1_ADDR_MASK));

    // Unmapped address detection
    assign decode_error = ~(s0_sel | s1_sel);

endmodule
