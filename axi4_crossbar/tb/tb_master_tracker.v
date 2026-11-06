`timescale 1ns / 1ps


module tb_master_tracker;

reg aclk;
reg aresetn;

// Master 0 events
reg m0_ar_accept;
reg m0_read_complete;
reg m0_aw_accept;
reg m0_write_complete;

// Master 1 events
reg m1_ar_accept;
reg m1_read_complete;
reg m1_aw_accept;
reg m1_write_complete;

// Busy outputs
wire m0_read_busy;
wire m0_write_busy;
wire m1_read_busy;
wire m1_write_busy;

// Availability outputs
wire m0_read_available;
wire m0_write_available;
wire m1_read_available;
wire m1_write_available;

integer errors;

// DUT instantiation
master_tracker DUT (
.aclk(aclk),
.aresetn(aresetn),

.m0_ar_accept(m0_ar_accept),
.m0_read_complete(m0_read_complete),
.m0_aw_accept(m0_aw_accept),
.m0_write_complete(m0_write_complete),

.m1_ar_accept(m1_ar_accept),
.m1_read_complete(m1_read_complete),
.m1_aw_accept(m1_aw_accept),
.m1_write_complete(m1_write_complete),

.m0_read_busy(m0_read_busy),
.m0_write_busy(m0_write_busy),
.m1_read_busy(m1_read_busy),
.m1_write_busy(m1_write_busy),

.m0_read_available(m0_read_available),
.m0_write_available(m0_write_available),
.m1_read_available(m1_read_available),
.m1_write_available(m1_write_available)
);

// Clock generation: 10 ns period
initial begin
aclk = 1'b0;
forever #5 aclk = ~aclk;
end

// Check all busy outputs
task check_status;
input exp_m0_read;
input exp_m0_write;
input exp_m1_read;
input exp_m1_write;

begin
@(negedge aclk);
#1;

if ((m0_read_busy  !== exp_m0_read)  ||
(m0_write_busy !== exp_m0_write) ||
(m1_read_busy  !== exp_m1_read)  ||
(m1_write_busy !== exp_m1_write)) begin

$display("FAIL: Transaction status mismatch");
$display("Expected M0 R/W=%b/%b, M1 R/W=%b/%b",
exp_m0_read, exp_m0_write,
exp_m1_read, exp_m1_write);

$display("Actual   M0 R/W=%b/%b, M1 R/W=%b/%b",
m0_read_busy, m0_write_busy,
m1_read_busy, m1_write_busy);

errors = errors + 1;
end
else begin
$display("PASS: M0 R/W=%b/%b, M1 R/W=%b/%b",
m0_read_busy, m0_write_busy,
m1_read_busy, m1_write_busy);
end

// Check availability outputs too
if ((m0_read_available  !== ~exp_m0_read)  ||
(m0_write_available !== ~exp_m0_write) ||
(m1_read_available  !== ~exp_m1_read)  ||
(m1_write_available !== ~exp_m1_write)) begin

$display("FAIL: Availability output mismatch");
errors = errors + 1;
end
end
endtask

// Test sequence
initial begin

errors = 0;

// Initialize inputs
aresetn = 1'b0;

m0_ar_accept = 0;
m0_read_complete = 0;
m0_aw_accept = 0;
m0_write_complete = 0;

m1_ar_accept = 0;
m1_read_complete = 0;
m1_aw_accept = 0;
m1_write_complete = 0;

$display("====================================");
$display(" MASTER TRACKER TEST STARTED");
$display("====================================");

// Apply reset
repeat (2) @(negedge aclk);
aresetn = 1'b1;

check_status(0, 0, 0, 0);

// Test 1: Master 0 starts a read
@(negedge aclk);
m0_ar_accept = 1;
@(negedge aclk);
m0_ar_accept = 0;

check_status(1, 0, 0, 0);

// Test 2: Master 0 starts a write while read is active
@(negedge aclk);
m0_aw_accept = 1;
@(negedge aclk);
m0_aw_accept = 0;

check_status(1, 1, 0, 0);

// Test 3: Master 1 starts a read and write
@(negedge aclk);
m1_ar_accept = 1;
m1_aw_accept = 1;
@(negedge aclk);
m1_ar_accept = 0;
m1_aw_accept = 0;

check_status(1, 1, 1, 1);

// Test 4: Complete Master 0 read
@(negedge aclk);
m0_read_complete = 1;
@(negedge aclk);
m0_read_complete = 0;

check_status(0, 1, 1, 1);

// Test 5: Complete Master 1 write
@(negedge aclk);
m1_write_complete = 1;
@(negedge aclk);
m1_write_complete = 0;

check_status(0, 1, 1, 0);

// Test 6: Complete remaining transactions
@(negedge aclk);
m0_write_complete = 1;
m1_read_complete = 1;
@(negedge aclk);
m0_write_complete = 0;
m1_read_complete = 0;

check_status(0, 0, 0, 0);

$display("====================================");

if (errors == 0)
$display("ALL TESTS PASSED!");
else
$display("TEST FAILED: %0d errors", errors);

$display("====================================");

$finish;
end

endmodule