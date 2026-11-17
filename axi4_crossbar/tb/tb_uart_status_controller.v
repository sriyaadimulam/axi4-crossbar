`timescale 1ns / 1ps

module tb_uart_status_controller;

    reg clk;
    reg resetn;
    reg start;

    reg [1:0] arb_policy;

    reg [31:0] m0_transaction_count;
    reg [31:0] m1_transaction_count;

    reg m0_error;
    reg m1_error;

    reg m0_active;
    reg m1_active;

    wire uart_tx;
    wire report_done;

    integer errors;
    integer received_bytes;

    localparam CLK_PERIOD = 10;
    localparam CLKS_PER_BIT = 868;

    uart_status_controller DUT (
        .clk(clk),
        .resetn(resetn),
        .start(start),

        .arb_policy(arb_policy),

        .m0_transaction_count(m0_transaction_count),
        .m1_transaction_count(m1_transaction_count),

        .m0_error(m0_error),
        .m1_error(m1_error),

        .m0_active(m0_active),
        .m1_active(m1_active),

        .uart_tx(uart_tx),
        .report_done(report_done)
    );

    // ----------------------------------------
    // 100 MHz CLOCK
    // ----------------------------------------

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // ----------------------------------------
    // UART BYTE RECEIVER
    // ----------------------------------------

   
task receive_byte;

    output [7:0] received_data;

    integer bit_number;

    begin

        // Wait for falling edge of UART start bit
        @(negedge uart_tx);

        // Sample middle of start bit (0.5 bit period)
        #(CLKS_PER_BIT * CLK_PERIOD / 2);

        if (uart_tx !== 1'b0) begin
            $display("FAIL: Invalid UART start bit");
            errors = errors + 1;
        end

        // Sample 8 data bits, LSB first
        for (bit_number = 0;
             bit_number < 8;
             bit_number = bit_number + 1) begin

            #(CLKS_PER_BIT * CLK_PERIOD);

            received_data[bit_number] = uart_tx;

        end

        // Sample stop bit
        #(CLKS_PER_BIT * CLK_PERIOD);

        if (uart_tx !== 1'b1) begin
            $display("FAIL: Invalid UART stop bit");
            errors = errors + 1;
        end

        received_bytes = received_bytes + 1;

    end

endtask


    
    // ----------------------------------------
    // MAIN TEST
    // ----------------------------------------

    reg [7:0] received_data;

    initial begin

        errors = 0;
        received_bytes = 0;

        resetn = 0;
        start = 0;

        arb_policy = 2'b01;

        m0_transaction_count = 32'd4;
        m1_transaction_count = 32'd4;

        m0_error = 0;
        m1_error = 0;

        m0_active = 0;
        m1_active = 0;

        repeat (5) @(posedge clk);

        @(negedge clk);
        resetn = 1;

        repeat (5) @(posedge clk);

        if (uart_tx !== 1'b1) begin
            $display("FAIL: UART idle line is not HIGH");
            errors = errors + 1;
        end
        else begin
            $display("PASS: UART idle line HIGH");
        end

        // Start report
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // Receive exactly 128 characters
        repeat (128) begin

            receive_byte(received_data);

            if ((received_data >= 8'h20) &&
                (received_data <= 8'h7E))
                $write("%c", received_data);

            else if (received_data == 8'h0D)
                $write("\n");

            else if (received_data == 8'h0A)
                $write("");

        end

        // Wait for report completion
        wait(report_done === 1'b1);

        $display("\nUART report transmission completed.");

        if (received_bytes == 128)
            $display("PASS: Received all 128 UART bytes");
        else begin
            $display("FAIL: Received %0d bytes",
                     received_bytes);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("\nALL UART TESTS PASSED");
        else
            $display("\nUART TEST FAILED: %0d errors", errors);

        $finish;

    end


    // ----------------------------------------
    // WATCHDOG
    // ----------------------------------------

    initial begin

        #20000000;

        $display("ERROR: UART testbench timeout");
        $finish;

    end

endmodule