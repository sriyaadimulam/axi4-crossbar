`timescale 1ns / 1ps

module axi4_zedboard_top (
    input  wire GCLK,
    output wire UART_TX,
    output wire [3:0] LED
);

    // Power-on reset
    reg [19:0] power_count = 0;
    reg resetn = 0;

    always @(posedge GCLK) begin
        if (!resetn) begin
            if (power_count == 20'd999999)
                resetn <= 1'b1;
            else
                power_count <= power_count + 1'b1;
        end
    end

    // Automatic demo start
    reg demo_start = 0;
    reg demo_started = 0;

    always @(posedge GCLK) begin
        if (!resetn) begin
            demo_start   <= 0;
            demo_started <= 0;
        end else if (!demo_started) begin
            demo_start   <= 1;
            demo_started <= 1;
        end else begin
            demo_start <= 0;
        end
    end

    // Wait before sending the UART status report
    reg [23:0] report_count = 0;
    reg report_start = 0;
    reg report_sent = 0;

    always @(posedge GCLK) begin
        if (!resetn) begin
            report_count <= 0;
            report_start <= 0;
            report_sent  <= 0;
        end else begin
            report_start <= 0;

            if (!report_sent) begin
                if (report_count == 24'd9999999) begin
                    report_start <= 1;
                    report_sent  <= 1;
                end else begin
                    report_count <= report_count + 1'b1;
                end
            end
        end
    end

    // Demo status signals
    wire [31:0] m0_count;
    wire [31:0] m1_count;
    wire m0_error, m1_error;
    wire m0_active, m1_active;
    
    // FPGA hardware status LEDs
    assign LED[0] = (m0_count >= 4);
    assign LED[1] = (m1_count >= 4);
    assign LED[2] = m0_error | m1_error;
    assign LED[3] = m0_active | m1_active;

    // Round-robin arbitration
    axi4_demo_top U_DEMO (
        .aclk(GCLK),
        .aresetn(resetn),
        .start(demo_start),
        .arb_policy(2'b01),

        .m0_transaction_count(m0_count),
        .m1_transaction_count(m1_count),
        .m0_error(m0_error),
        .m1_error(m1_error),
        .m0_active(m0_active),
        .m1_active(m1_active)
    );

    // UART status output
    wire report_done;

    uart_status_controller #(
        .CLK_FREQ(100_000_000),
        .BAUD_RATE(115200)
    ) U_UART_STATUS (
        .clk(GCLK),
        .resetn(resetn),
        .start(report_start),
        .arb_policy(2'b01),

        .m0_transaction_count(m0_count),
        .m1_transaction_count(m1_count),
        .m0_error(m0_error),
        .m1_error(m1_error),
        .m0_active(m0_active),
        .m1_active(m1_active),

        .uart_tx(UART_TX),
        .report_done(report_done)
    );

endmodule