///|
test "fixed pooling is weighted and copies results" {
  let s = [study("a", 1.0, 1.0), study("b", 3.0, 1.0)]
  let p = fixed(s)
  assert_eq(p.estimate(), 2.0)
  assert_eq(p.variance(), 0.5)
  assert_eq(p.residual_q(), 2.0)
  let w = p.weights()
  w[0] = 99.0
  assert_eq(p.weights()[0], 0.5)
  assert_eq(p.tau2(), 0.0)
}

///|
test "inverse variance ratio and unrepresentable residuals" {
  let s = [study("a", 0.0, 1.0), study("b", 10.0, 4.0)]
  assert_true((fixed(s).estimate() - 2.0).abs() < 1.0e-12)
  assert_true(
    try {
      ignore(pool_at(s, -1.0))
      false
    } catch {
      _ => true
    },
  )
  assert_true(
    try {
      ignore(fixed([study("a", 1.0e308, 1.0), study("b", -1.0e308, 1.0)]))
      false
    } catch {
      _ => true
    },
  )
}
