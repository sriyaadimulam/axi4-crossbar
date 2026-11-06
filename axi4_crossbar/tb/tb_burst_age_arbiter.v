`timescale 1ns / 1ps


module tb_burst_age_arbiter;

reg aclk;
reg aresetn;

reg [1:0] req;
reg arb_enable;

reg grant_accept;

reg service_valid;
reg service_master;

reg epoch_clear;

wire [1:0] grant;

integer errors;

burst_age_arbiter DUT (

.aclk(aclk),
.aresetn(aresetn),

.req(req),
.arb_enable(arb_enable),

.grant_accept(grant_accept),

.service_valid(service_valid),
.service_master(service_master),

.epoch_clear(epoch_clear),

.grant(grant)

    );

// Clock generation
initial begin
aclk = 1'b0;
forever #5 aclk = ~aclk;
end

// Reset task
task reset_dut;
begin

req = 2'b00;
arb_enable = 1'b0;

grant_accept = 1'b0;

service_valid = 1'b0;
service_master = 1'b0;

epoch_clear = 1'b0;

aresetn = 1'b0;

repeat (2) @(posedge aclk);

@(negedge aclk);
aresetn = 1'b1;

#1;

end
endtask

// Grant checking task
task check_grant;

input [1:0] test_req;
input test_enable;
input [1:0] expected_grant;

begin

@(negedge aclk);

req = test_req;
arb_enable = test_enable;

#1;

if (grant !== expected_grant) begin

$display(
"FAIL: req=%b enable=%b expected=%b actual=%b",
test_req, test_enable,
expected_grant, grant
);

errors = errors + 1;

end

else begin

$display(
"PASS: req=%b enable=%b grant=%b",
test_req, test_enable, grant
);

end

end

endtask

// Accept currently selected grant
task accept_grant;

begin

@(negedge aclk);
grant_accept = 1'b1;

@(posedge aclk);
#1;

@(negedge aclk);
grant_accept = 1'b0;

end

endtask

// Send service beats for a selected master
task send_service;

input master_id;
input integer beats;

integer i;

begin

@(negedge aclk);

service_master = master_id;
service_valid = 1'b1;

for (i = 0; i < beats; i = i + 1)
@(posedge aclk);

@(negedge aclk);
service_valid = 1'b0;

end

endtask

// Main test sequence
initial begin

errors = 0;

$display("====================================");
$display(" BURST AGE ARBITER TEST STARTED");
$display("====================================");

// TEST 1: Reset and no requests
reset_dut();

check_grant(2'b00, 1'b1, 2'b00);

// TEST 2: Only Master 0 requests
reset_dut();

check_grant(2'b01, 1'b1, 2'b01);

// TEST 3: Only Master 1 requests
reset_dut();

check_grant(2'b10, 1'b1, 2'b10);

// TEST 4: Equal scores; initial tie-break is M0
reset_dut();

check_grant(2'b11, 1'b1, 2'b01);

// TEST 5: Accepted M0 grant changes tie-break to M1
accept_grant();

@(negedge aclk);
req = 2'b00;
arb_enable = 1'b0;

repeat (2) @(posedge aclk);

check_grant(2'b11, 1'b1, 2'b10);

// TEST 6: Waiting age gives M0 higher score
reset_dut();

// Keep arbitration disabled while M0 waits
@(negedge aclk);
req = 2'b01;
arb_enable = 1'b0;

repeat (4) @(posedge aclk);

// M1 begins waiting later
@(negedge aclk);
req = 2'b11;

repeat (1) @(posedge aclk);

check_grant(2'b11, 1'b1, 2'b01);

// TEST 7: Service penalty favors less-served M1
reset_dut();

// Accumulate three service beats for M0
send_service(1'b0, 3);

check_grant(2'b11, 1'b1, 2'b10);

// TEST 8: Grant remains stable during backpressure
reset_dut();

@(negedge aclk);
req = 2'b11;
arb_enable = 1'b1;

#1;

if (grant !== 2'b01) begin
$display("FAIL: Initial locked grant was incorrect");
errors = errors + 1;
end

// Allow the arbiter to capture its grant
@(posedge aclk);
#1;

// Increase service for M0 while grant is locked
send_service(1'b0, 3);

if (grant !== 2'b01) begin
$display("FAIL: Grant changed during backpressure");
errors = errors + 1;
end
else begin
$display("PASS: Grant remained stable during backpressure");
end

// TEST 9: Clear service history
reset_dut();

send_service(1'b0, 3);

@(negedge aclk);
epoch_clear = 1'b1;

@(posedge aclk);
#1;

@(negedge aclk);
epoch_clear = 1'b0;

check_grant(2'b11, 1'b1, 2'b01);

$display("====================================");

if (errors == 0)
$display("ALL TESTS PASSED!");

else
$display("TEST FAILED: %0d errors", errors);

$display("====================================");

$finish;

end

endmodule