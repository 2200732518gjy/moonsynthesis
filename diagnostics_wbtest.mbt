test "study Q contributions and normalized weights sum to the fitted quantities" {
  let s = [study("a", -1.0, 0.2), study("b", 1.0, 0.4), study("c", 0.2, 0.3)]
  let rows = summarize_studies(s)
  let mut q = 0.0
  let mut w = 0.0
  for row in rows { q = q + row.q_contribution; w = w + row.weight }
  assert_true((w - 1.0).abs() < 1.0e-12)
  assert_true((q - analyze(s).pool.residual_q).abs() < 1.0e-10)
  let ratio = exponentiate_interval({ lower: @math.ln(0.5), upper: @math.ln(2.0) })
  assert_true((ratio.lower - 0.5).abs() < 1.0e-12)
  assert_true((ratio.upper - 2.0).abs() < 1.0e-12)
}
