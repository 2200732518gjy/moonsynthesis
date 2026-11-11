///|
/// Regression checks use independent distribution constants and structural laws.
test "tail critical values and exact Cauchy quantiles" {
  assert_true((normal_critical(0.0001) - 3.890591886413094).abs() < 1.0e-7)
  assert_true((normal_critical(0.5) - 0.6744897501960817).abs() < 1.0e-7)
  for alpha in [0.0001, 0.001, 0.01, 0.05, 0.5] {
    let exact = 1.0 / @math.tan(alpha * 3.141592653589793 / 2.0)
    assert_true((student_critical(alpha, 1) / exact - 1.0).abs() < 1.0e-8)
  }
}

///|
test "pooling permutation translation and scale covariance" {
  let s = [study("a", -2.0, 0.3), study("b", 1.0, 0.5), study("c", 3.0, 0.7)]
  let p = random_pm(s)
  let r = random_pm([s[2], s[0], s[1]])
  assert_true((p.estimate - r.estimate).abs() < 1.0e-12)
  let translated = random_pm(
    s.map(x => study(x.id, x.effect + 10.0, x.variance)),
  )
  assert_true((translated.estimate - p.estimate - 10.0).abs() < 1.0e-10)
  assert_true((translated.tau2 - p.tau2).abs() < 1.0e-10)
}

///|
test "public validator and computational budgets cannot be bypassed" {
  let bad = try {
    validate_studies([], -1)
    false
  } catch {
    _ => true
  }
  assert_true(bad)
  let many : Array[Study] = []
  for i in 0..<65 {
    many.push(study(i.to_string(), 1.0, 1.0))
  }
  let bad = try {
    ignore(leave_one_out(many))
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
