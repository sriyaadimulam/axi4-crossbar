`timescale 1ns / 1ps

module uart_tx #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input wire clk,
    input wire resetn,

    input wire [7:0] tx_data,
    input wire tx_start,

    output reg tx,
    output reg tx_busy,
    output reg tx_done
);

    localparam integer CLKS_PER_BIT =
        CLK_FREQ / BAUD_RATE;

    localparam integer CNT_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state;
    reg [CNT_WIDTH-1:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] data_reg;

    always @(posedge clk or negedge resetn) begin

        if (!resetn) begin
            state     <= IDLE;
            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            data_reg  <= 0;
        end

        else begin

            tx_done <= 1'b0;

            case (state)

                IDLE: begin

                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin

                        data_reg <= tx_data;
                        tx_busy  <= 1'b1;
                        tx       <= 1'b0;

                        state <= START;

                    end

                end

                START: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;
                        bit_index <= 0;

                        tx <= data_reg[0];

                        state <= DATA;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                DATA: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        if (bit_index == 7) begin

                            tx <= 1'b1;

                            state <= STOP;

                        end
                        else begin

                            bit_index <= bit_index + 1'b1;

                            tx <= data_reg[bit_index + 1'b1];

                        end

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                STOP: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        tx <= 1'b1;
                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;

                        state <= IDLE;

                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end

                end

                default: begin

                    state <= IDLE;
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= 0;

                end

            endcase

        end

    end

endmodule