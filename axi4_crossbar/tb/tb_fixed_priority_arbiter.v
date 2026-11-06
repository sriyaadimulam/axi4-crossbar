
`timescale 1ns / 1ps


module tb_fixed_priority_arbiter;

reg  [1:0] req;
wire [1:0] grant;

integer errors;

// Device Under Test
fixed_priority_arbiter DUT (
.req   (req),
.grant (grant)
);

// Task to verify arbitration result
task check_request;
input [1:0] test_req;
input [1:0] expected_grant;

begin
req = test_req;
#10;

if (grant !== expected_grant) begin

$display("FAIL: req=%b expected grant=%b actual grant=%b",
test_req, expected_grant, grant);

errors = errors + 1;

end
else begin

$display("PASS: req=%b grant=%b",
test_req, grant);

end
end
endtask

// Test sequence
initial begin

errors = 0;
req = 2'b00;

$display("====================================");
$display(" FIXED PRIORITY ARBITER TEST STARTED");
$display("====================================");

// Test 1: No requests
check_request(2'b00, 2'b00);

// Test 2: Only Master 1 requests
check_request(2'b10, 2'b10);

// Test 3: Only Master 0 requests
check_request(2'b01, 2'b01);

// Test 4: Both masters request
check_request(2'b11, 2'b01);

$display("====================================");

if (errors == 0)
$display("ALL TESTS PASSED!");
else
$display("TEST FAILED: %0d errors", errors);

$display("====================================");

$finish;

end

endmodule