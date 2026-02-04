# Weighted Round Robin Arbiter -Assertion Based Verification
This project implements a weighted round-robin arbiter in SystemVerilog for sharing resources between multiple requesters. Each requester is given a weight, and grants are given based on weight and round-robin order. The design is verified using SystemVerilog assertions with a reference model.

Design Description:
*********************************************************************************************
The weighted_round_robin module arbitrates among N requesters using assigned weights.
Each requester is given a number of tokens (weights) that represent its priority.

How It Works:
*********************************************************************************************
Each requester maintains a weight counter.
Only active requesters are considered.
Among active requests, those with the highest remaining weight are selected.
If multiple requesters have the same weight, round-robin scheduling is applied.
One requester is granted per cycle.
The winner’s weight is decremented.
The round-robin pointer is updated.

This approach ensures:
*********************************************************************************************
Higher-weight requesters get more service
Equal-weight requesters are treated fairly
No requester is starved

Verification Method:
*********************************************************************************************
Verification is done using SystemVerilog Assertions.
A reference model is implemented in the SVA module.
The reference model calculates the expected grant every cycle.
The DUT output is compared with the reference model.
Additional assertions check correctness and fairness.
The checker is connected using a bind file, so the RTL is not modified.
