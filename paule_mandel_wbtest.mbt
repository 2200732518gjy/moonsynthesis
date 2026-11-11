///|
test "PM solves residual equation with unequal study variances" {
  let s = [study("a", -1.0, 0.01), study("b", 1.0, 0.5), study("c", 2.0, 0.3)]
  let p = random_pm(s)
  assert_true(p.tau2() > 0.0)
  assert_true((p.residual_q() - 2.0).abs() < 1.0e-10)
}

///|
test "PM handles zero root and scale covariance" {
  assert_eq(tau_pm([study("a", 0.0, 0.01), study("b", 0.01, 0.01)]), 0.0)
  let base = [study("a", 1.0, 1.0), study("b", 5.0, 1.0), study("c", 3.0, 1.0)]
  let scaled = [
    study("a", 10.0, 100.0),
    study("b", 50.0, 100.0),
    study("c", 30.0, 100.0),
  ]
  assert_true((tau_pm(scaled) - 100.0 * tau_pm(base)).abs() < 1.0e-9)
}
