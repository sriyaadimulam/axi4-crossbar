`timescale 1ns / 1ps


module tb_axi4_crossbar_b_router_slots;

reg aclk;
reg aresetn;

reg [3:0] s0_bid, s1_bid;
reg [1:0] s0_bresp, s1_bresp;
reg s0_bvalid, s1_bvalid;
wire s0_bready, s1_bready;

wire [3:0] m0_bid, m1_bid;
wire [1:0] m0_bresp, m1_bresp;
wire m0_bvalid, m1_bvalid;
reg m0_bready, m1_bready;

reg s0_aw_accept, s1_aw_accept;
reg s0_aw_owner, s1_aw_owner;

wire s0_write_slot_available;
wire s1_write_slot_available;

integer pass_count;
integer fail_count;

axi4_crossbar_b_router #(
.ID_WIDTH(4)
) DUT (
.aclk(aclk),
.aresetn(aresetn),

.m0_bid(m0_bid),
.m0_bresp(m0_bresp),
.m0_bvalid(m0_bvalid),
.m0_bready(m0_bready),

.m1_bid(m1_bid),
.m1_bresp(m1_bresp),
.m1_bvalid(m1_bvalid),
.m1_bready(m1_bready),

.s0_bid(s0_bid),
.s0_bresp(s0_bresp),
.s0_bvalid(s0_bvalid),
.s0_bready(s0_bready),

.s1_bid(s1_bid),
.s1_bresp(s1_bresp),
.s1_bvalid(s1_bvalid),
.s1_bready(s1_bready),

.s0_aw_accept(s0_aw_accept),
.s0_aw_owner(s0_aw_owner),
.s1_aw_accept(s1_aw_accept),
.s1_aw_owner(s1_aw_owner),

.s0_write_slot_available(s0_write_slot_available),
.s1_write_slot_available(s1_write_slot_available)
);

initial begin
aclk = 0;
forever #5 aclk = ~aclk;
end

task check_slots;
input expected_s0;
input expected_s1;
input [8*60-1:0] test_name;
begin
#1;
if ((s0_write_slot_available === expected_s0) &&
(s1_write_slot_available === expected_s1)) begin
$display("PASS: %0s | S0=%b S1=%b",
test_name,
s0_write_slot_available,
s1_write_slot_available);
pass_count = pass_count + 1;
end
else begin
$display("FAIL: %0s | Expected S0=%b S1=%b, Got S0=%b S1=%b",
test_name,
expected_s0, expected_s1,
s0_write_slot_available,
s1_write_slot_available);
fail_count = fail_count + 1;
end
end
endtask

initial begin

pass_count = 0;
fail_count = 0;

aresetn = 0;

s0_bid = 0;
s1_bid = 0;
s0_bresp = 0;
s1_bresp = 0;
s0_bvalid = 0;
s1_bvalid = 0;

m0_bready = 0;
m1_bready = 0;

s0_aw_accept = 0;
s1_aw_accept = 0;
s0_aw_owner = 0;
s1_aw_owner = 0;

repeat (2) @(posedge aclk);
@(negedge aclk);
aresetn = 1;

$display("==============================================");
$display(" B ROUTER WRITE-SLOT TEST STARTED");
$display("==============================================");

// TEST 1: Both slots initially available
check_slots(1, 1, "Both slots initially available");

// TEST 2: S0 accepts an AW from M0
@(negedge aclk);
s0_aw_accept = 1;
s0_aw_owner = 0;

@(posedge aclk);
#1;
check_slots(0, 1, "S0 occupied after AW acceptance");

// TEST 3: S1 accepts an AW from M1 independently
@(negedge aclk);
s0_aw_accept = 0;
s1_aw_accept = 1;
s1_aw_owner = 1;

@(posedge aclk);
#1;
check_slots(0, 0, "Both slave slots occupied");

// TEST 4: S0 B response arrives, but M0 is not ready
@(negedge aclk);
s1_aw_accept = 0;
s0_bvalid = 1;
s0_bid = 4'h3;
s0_bresp = 2'b00;
m0_bready = 0;

#1;
if (m0_bvalid && !s0_bready) begin
$display("PASS: S0 B response held under backpressure");
pass_count = pass_count + 1;
end
else begin
$display("FAIL: S0 B response backpressure");
fail_count = fail_count + 1;
end

check_slots(0, 0, "S0 slot remains occupied under backpressure");

// TEST 5: Accept S0 B response
@(negedge aclk);
m0_bready = 1;

@(posedge aclk);
#1;
check_slots(1, 0, "S0 slot released after B handshake");

// TEST 6: Accept S1 B response
@(negedge aclk);
s0_bvalid = 0;
m0_bready = 0;
s1_bvalid = 1;
s1_bid = 4'h7;
s1_bresp = 2'b00;
m1_bready = 1;

@(posedge aclk);
#1;
check_slots(1, 1, "Both slots available after B handshakes");

// Summary
$display("----------------------------------------------");
$display(" B ROUTER SLOT TEST SUMMARY");
$display(" PASSED : %0d", pass_count);
$display(" FAILED : %0d", fail_count);
$display("----------------------------------------------");

if (fail_count == 0)
$display("ALL TESTS PASSED!");
else
$display("SOME TESTS FAILED!");

#20;
$finish;
end

endmodule