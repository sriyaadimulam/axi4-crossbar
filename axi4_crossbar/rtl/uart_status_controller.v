`timescale 1ns / 1ps

module uart_status_controller #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire resetn,
    input wire start,

    input wire [1:0] arb_policy,

    input wire [31:0] m0_transaction_count,
    input wire [31:0] m1_transaction_count,

    input wire m0_error,
    input wire m1_error,

    input wire m0_active,
    input wire m1_active,

    output wire uart_tx,
    output reg report_done
);

    localparam IDLE = 2'd0;
    localparam SEND = 2'd1;
    localparam WAIT = 2'd2;
    localparam DONE = 2'd3;

    reg [1:0] state;

    reg [7:0] message [0:127];

    reg [6:0] message_length;
    reg [6:0] message_index;

    reg tx_start;
    reg [7:0] tx_data;

    wire tx_busy;
    wire tx_done;

    reg [31:0] m0_count_reg;
    reg [31:0] m1_count_reg;

    reg m0_error_reg;
    reg m1_error_reg;

    reg m0_active_reg;
    reg m1_active_reg;

    reg [1:0] policy_reg;

    integer i;

    // ------------------------------------------------
    // HEXADECIMAL TO ASCII
    // ------------------------------------------------

    function [7:0] hex_ascii;

        input [3:0] value;

        begin

            if (value < 10)
                hex_ascii = "0" + value;
            else
                hex_ascii = "A" + (value - 10);

        end

    endfunction

    // ------------------------------------------------
    // UART TRANSMITTER
    // ------------------------------------------------

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) UART_TRANSMITTER (
        .clk(clk),
        .resetn(resetn),
        .tx_data(tx_data),
        .tx_start(tx_start),
        .tx(uart_tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    // ------------------------------------------------
    // MESSAGE CONTROLLER
    // ------------------------------------------------

    always @(posedge clk or negedge resetn) begin

        if (!resetn) begin

            state <= IDLE;

            message_length <= 0;
            message_index <= 0;

            tx_start <= 0;
            tx_data <= 0;

            report_done <= 0;

            m0_count_reg <= 0;
            m1_count_reg <= 0;

            m0_error_reg <= 0;
            m1_error_reg <= 0;

            m0_active_reg <= 0;
            m1_active_reg <= 0;

            policy_reg <= 0;

            for (i = 0; i < 128; i = i + 1)
                message[i] <= 0;

        end

        else begin

            tx_start <= 0;

            case (state)

                // ------------------------------------
                // IDLE
                // ------------------------------------

                IDLE: begin

                    report_done <= 0;

                    if (start) begin

                        // Capture current status
                        m0_count_reg <= m0_transaction_count;
                        m1_count_reg <= m1_transaction_count;

                        m0_error_reg <= m0_error;
                        m1_error_reg <= m1_error;

                        m0_active_reg <= m0_active;
                        m1_active_reg <= m1_active;

                        policy_reg <= arb_policy;

                        // PROJECT HEADER
                        message[0]  <= "A";
                        message[1]  <= "X";
                        message[2]  <= "I";
                        message[3]  <= "4";
                        message[4]  <= " ";
                        message[5]  <= "C";
                        message[6]  <= "R";
                        message[7]  <= "O";
                        message[8]  <= "S";
                        message[9]  <= "S";
                        message[10] <= "B";
                        message[11] <= "A";
                        message[12] <= "R";
                        message[13] <= 8'h0D;
                        message[14] <= 8'h0A;

                        // POLICY
                        message[15] <= "P";
                        message[16] <= "O";
                        message[17] <= "L";
                        message[18] <= "I";
                        message[19] <= "C";
                        message[20] <= "Y";
                        message[21] <= ":";

                        case (arb_policy)

                            2'b00: message[22] <= "F";
                            2'b01: message[22] <= "R";
                            2'b10: message[22] <= "A";
                            default: message[22] <= "X";

                        endcase

                        message[23] <= 8'h0D;
                        message[24] <= 8'h0A;

                        // MASTER 0 COUNT LABEL
                        message[25] <= "M";
                        message[26] <= "0";
                        message[27] <= " ";
                        message[28] <= "C";
                        message[29] <= "O";
                        message[30] <= "U";
                        message[31] <= "N";
                        message[32] <= "T";
                        message[33] <= ":";

                        message[34] <= " ";
                        message[35] <= "0";
                        message[36] <= "x";

                        // MASTER 0 COUNT HEX DIGITS
                        message[37] <= hex_ascii(m0_transaction_count[31:28]);
                        message[38] <= hex_ascii(m0_transaction_count[27:24]);
                        message[39] <= hex_ascii(m0_transaction_count[23:20]);
                        message[40] <= hex_ascii(m0_transaction_count[19:16]);
                        message[41] <= hex_ascii(m0_transaction_count[15:12]);
                        message[42] <= hex_ascii(m0_transaction_count[11:8]);
                        message[43] <= hex_ascii(m0_transaction_count[7:4]);
                        message[44] <= hex_ascii(m0_transaction_count[3:0]);

                        message[45] <= 8'h0D;
                        message[46] <= 8'h0A;

                        // MASTER 1 COUNT LABEL
                        message[47] <= "M";
                        message[48] <= "1";
                        message[49] <= " ";
                        message[50] <= "C";
                        message[51] <= "O";
                        message[52] <= "U";
                        message[53] <= "N";
                        message[54] <= "T";
                        message[55] <= ":";

                        message[56] <= " ";
                        message[57] <= "0";
                        message[58] <= "x";

                        // MASTER 1 COUNT HEX DIGITS
                        message[59] <= hex_ascii(m1_transaction_count[31:28]);
                        message[60] <= hex_ascii(m1_transaction_count[27:24]);
                        message[61] <= hex_ascii(m1_transaction_count[23:20]);
                        message[62] <= hex_ascii(m1_transaction_count[19:16]);
                        message[63] <= hex_ascii(m1_transaction_count[15:12]);
                        message[64] <= hex_ascii(m1_transaction_count[11:8]);
                        message[65] <= hex_ascii(m1_transaction_count[7:4]);
                        message[66] <= hex_ascii(m1_transaction_count[3:0]);

                        message[67] <= 8'h0D;
                        message[68] <= 8'h0A;

                        // MASTER 0 ERROR
                        message[69] <= "M";
                        message[70] <= "0";
                        message[71] <= " ";
                        message[72] <= "E";
                        message[73] <= "R";
                        message[74] <= "R";
                        message[75] <= ":";

                        message[76] <= m0_error ? "1" : "0";

                        message[77] <= 8'h0D;
                        message[78] <= 8'h0A;

                        // MASTER 1 ERROR
                        message[79] <= "M";
                        message[80] <= "1";
                        message[81] <= " ";
                        message[82] <= "E";
                        message[83] <= "R";
                        message[84] <= "R";
                        message[85] <= ":";

                        message[86] <= m1_error ? "1" : "0";

                        message[87] <= 8'h0D;
                        message[88] <= 8'h0A;

                        // MASTER ACTIVITY
                        message[89] <= "M";
                        message[90] <= "0";
                        message[91] <= " ";
                        message[92] <= "A";
                        message[93] <= "C";
                        message[94] <= "T";
                        message[95] <= "I";
                        message[96] <= "V";
                        message[97] <= "E";
                        message[98] <= ":";

                        message[99] <= m0_active ? "1" : "0";

                        message[100] <= 8'h0D;
                        message[101] <= 8'h0A;

                        message[102] <= "M";
                        message[103] <= "1";
                        message[104] <= " ";
                        message[105] <= "A";
                        message[106] <= "C";
                        message[107] <= "T";
                        message[108] <= "I";
                        message[109] <= "V";
                        message[110] <= "E";
                        message[111] <= ":";

                        message[112] <= m1_active ? "1" : "0";

                        message[113] <= 8'h0D;
                        message[114] <= 8'h0A;

                        // COMPLETION MESSAGE
                        message[115] <= "R";
                        message[116] <= "E";
                        message[117] <= "P";
                        message[118] <= "O";
                        message[119] <= "R";
                        message[120] <= "T";
                        message[121] <= " ";
                        message[122] <= "C";
                        message[123] <= "O";
                        message[124] <= "M";
                        message[125] <= "P";
                        message[126] <= "L";
                        message[127] <= "E";

                        // The message buffer has 128 entries.
                        // Send the first 128 bytes.
                        message_index <= 0;
                        message_length <= 128;

                        state <= SEND;

                    end

                end

                // ------------------------------------
                // SEND CHARACTER
                // ------------------------------------

                SEND: begin

                    if (!tx_busy) begin

                        tx_data <= message[message_index];

                        tx_start <= 1;

                        state <= WAIT;

                    end

                end

                // ------------------------------------
                // WAIT FOR UART
                // ------------------------------------

                WAIT: begin

                    if (tx_done) begin

                        if (message_index == message_length - 1) begin

                            state <= DONE;

                        end

                        else begin

                            message_index <=
                                message_index + 1'b1;

                            state <= SEND;

                        end

                    end

                end

                // ------------------------------------
                // REPORT COMPLETE
                // ------------------------------------

                DONE: begin

                    report_done <= 1;

                    state <= DONE;

                end

                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule