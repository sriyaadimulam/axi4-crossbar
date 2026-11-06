`timescale 1ns / 1ps


module tb_address_decoder;

reg  [31:0] addr;

wire s0_sel;
wire s1_sel;
wire decode_error;

integer errors;

// Device Under Test
address_decoder DUT (
.addr         (addr),
.s0_sel       (s0_sel),
.s1_sel       (s1_sel),
.decode_error (decode_error)
);

// Address checking task
task check_addr;
input [31:0] test_addr;
input expected_s0;
input expected_s1;
input expected_error;

begin
addr = test_addr;
#10;
if ((s0_sel !== expected_s0) ||
    (s1_sel !== expected_s1) ||
    (decode_error !== expected_error)) begin

$display("FAIL: Address = %h", test_addr);
$display("Expected: %b %b %b",
expected_s0, expected_s1, expected_error);
$display("Actual:   %b %b %b",
s0_sel, s1_sel, decode_error);

errors = errors + 1;
end
else begin
$display("PASS: Address = %h", test_addr);
end
end
endtask

// Test sequence
initial begin

errors = 0;
addr = 32'h00000000;

$display("================================");
$display(" ADDRESS DECODER TEST START");
$display("================================");

// Slave 0 tests
check_addr(32'h00000000, 1'b1, 1'b0, 1'b0);
check_addr(32'h00001234, 1'b1, 1'b0, 1'b0);
check_addr(32'h0000FFFF, 1'b1, 1'b0, 1'b0);

// Slave 1 tests
check_addr(32'h00010000, 1'b0, 1'b1, 1'b0);
check_addr(32'h0001ABCD, 1'b0, 1'b1, 1'b0);
check_addr(32'h0001FFFF, 1'b0, 1'b1, 1'b0);

// Unmapped address tests
check_addr(32'h00020000, 1'b0, 1'b0, 1'b1);
check_addr(32'hFFFF0000, 1'b0, 1'b0, 1'b1);

$display("================================");

if (errors == 0)
$display("ALL TESTS PASSED!");
else
$display("TEST FAILED: %0d errors", errors);

$display("================================");

$finish;
end

endmodule