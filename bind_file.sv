bind weighted_round_robin
  weighted_round_robin_sva #(.N(N), .W(W)) u_wrr_sva (
    .i_clk     (i_clk),
    .i_rstn    (i_rstn),
    .i_en      (i_en),
    .i_req     (i_req),
    .i_load    (i_load),
    .i_weights (i_weights),
    .o_gnt     (o_gnt)
  );

