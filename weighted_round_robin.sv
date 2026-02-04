module weighted_round_robin #(
    parameter N = 8,  // Number of requesters
    parameter W = 3   // Width of weight counters
)(
    input  logic                     i_clk,
    input  logic                     i_rstn,
    input  logic                     i_en,
    input  logic [N-1:0]             i_req,      // Now N is defined
    input  logic                     i_load,     // Load weights pulse
    input  logic [N-1:0] [W-1:0]     i_weights,  // Now W is defined
    output logic [N-1:0]             o_gnt
);

  //--------------------------------------------------------------------------
  // Local Parameters
  //--------------------------------------------------------------------------
  localparam M = $clog2(N);         // Width of the pointer

  //--------------------------------------------------------------------------
  // Internal Signals
  //--------------------------------------------------------------------------
  logic [M-1:0]          ptr;              // Current Round Robin pointer
  logic [M-1:0]          ptr_arb;          // Next pointer (index of the winner)
  
  // Rotating Priority Logic Signals
  logic [N-1:0]          rotate_r;         // Rotated request vector
  logic [N-1:0]          priority_out;     // Grant vector (rotated)
  logic [N-1:0]          gnt;              // Final Grant vector (un-rotated)
  logic [N-1:0]          tmp_r, tmp_l;     // Temporary signals for barrel shifter

  // Weighted Logic Signals
  logic [N-1:0] [W-1:0]  weight_counters;  // Current weight count for each requester
  logic [N-1:0] [W-1:0]  masked;           // Weights of currently active requests
  logic [W-1:0]          max;              // Maximum weight among active requests
  logic [N-1:0]          req_w;            // Filtered request vector (only max weights)

  //--------------------------------------------------------------------------
  // 1. Weight Masking & Max Calculation
  //--------------------------------------------------------------------------
  // Mask weights: if a request is 0, its effective weight is considered 0
  always_comb begin
    for (int i = 0; i < N; i++) begin
      if (i_req[i])
        masked[i] = weight_counters[i];
      else
        masked[i] = '0;
    end
  end

  // Find the maximum weight among the currently active requests
  always_comb begin
    max = '0;
    for (int i = 0; i < N; i++) begin
      if (masked[i] > max)
        max = masked[i];
    end
  end

  // Generate req_w: Only requests that have the Maximum weight are considered for arbitration
  always_comb begin
    req_w = '0;
    for (int i = 0; i < N; i++) begin
      if ((masked[i] == max) && (i_req[i]))
        req_w[i] = 1'b1;
      else 
        req_w[i] = 1'b0;
    end
  end

  //--------------------------------------------------------------------------
  // 2. Round Robin Arbitration Core (Rotate -> Prioritize -> Rotate Back)
  //--------------------------------------------------------------------------
  
  // Rotate Right: Align the request vector so the bit at 'ptr' is at LSB
  assign {tmp_r, rotate_r} = {2{req_w}} >> ptr;

  // Priority Encoder: Find the first '1' (LSB)
  assign priority_out = rotate_r & ~(rotate_r - 1);

  // Rotate Left: Restore the original position of the grant
  assign {gnt, tmp_l} = {2{priority_out}} << ptr;

  // Calculate the index of the winner (to update the pointer later)
  always_comb begin
    ptr_arb = ptr; // Default to current
    for (int i = 0; i < N; i++) begin
      if (gnt[i])
        ptr_arb = i[M-1:0];
    end
  end

  //--------------------------------------------------------------------------
  // 3. Sequential Logic: Updates & Outputs
  //--------------------------------------------------------------------------
  always_ff @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      ptr             <= '0;
      o_gnt           <= '0;
      weight_counters <= '0;
    end
    else begin
      // Weight Loading Logic
      if (i_load) begin
        weight_counters <= i_weights;
      end
      // Decrement Weight Logic
      // Only decrement if arbitration happened (gnt!=0) and weight > 0
      else if (i_en && (|gnt) && (weight_counters[ptr_arb] > 0)) begin
        weight_counters[ptr_arb] <= weight_counters[ptr_arb] - 1'b1;
      end

      // Pointer & Output Update Logic
      if (i_en) begin
        // Update pointer to Next(Winner)
        if (ptr_arb == N - 1)
          ptr <= '0;
        else
          ptr <= ptr_arb + 1'b1;

        o_gnt <= gnt;
      end
    end
  end

endmodule
