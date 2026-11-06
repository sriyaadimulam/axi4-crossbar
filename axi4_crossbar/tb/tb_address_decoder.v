`timescale 1ns / 1ps


module tb_address_decoder;

reg  [31:0] addr;

wire s0_sel;
wire s1_sel;
wire decode_error;

integer errors;

// Instantiate DUT (Design Under Test)
address_decoder DUT (
.addr         (addr),
.s0_sel       (s0_sel),
.s1_sel       (s1_sel),
.decode_error (decode_error)
);

// Address decoder verification task
task check_address;
input [31:0] test_addr;
input exp_s0;
input exp_s1;
input exp_error;

begin
addr = test_addr;
#10;
if ((s0_sel       !== exp_s0)		

(decode_error !== exp_error)) begin

$display("FAIL: Address = %h", test_addr);
$display("Expected: S0=%b S1=%b ERR=%b",
exp_s0, exp_s1, exp_error);
$display("Actual:   S0=%b S1=%b ERR=%b",
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
addr   = 32'h00000000;

$display("----------------------------------");
$display(" ADDRESS DECODER TEST STARTED");
$display("----------------------------------");

// Slave 0 address range
check_address(32'h00000000, 1'b1, 1'b0, 1'b0);
check_address(32'h00001234, 1'b1, 1'b0, 1'b0);
check_address(32'h0000FFFF, 1'b1, 1'b0, 1'b0);

// Slave 1 address range
check_address(32'h00010000, 1'b0, 1'b1, 1'b0);
check_address(32'h0001ABCD, 1'b0, 1'b1, 1'b0);
check_address(32'h0001FFFF, 1'b0, 1'b1, 1'b0);

// Unmapped addresses
check_address(32'h00020000, 1'b0, 1'b0, 1'b1);
check_address(32'hFFFF0000, 1'b0, 1'b0, 1'b1);

$display("----------------------------------");

if (errors == 0)
$display("ALL TESTS PASSED!");
else
$display("TEST FAILED: %0d errors", errors);

$display("----------------------------------");

$finish;
end

endmodule