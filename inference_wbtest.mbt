///|
test "normal and conservative HK intervals carry explicit model choices" {
  let s = [study("a", 0.0, 1.0), study("b", 2.0, 1.0), study("c", 4.0, 1.0)]
  let n = analyze(s, model=DL, inference=Normal)
  let h = analyze(s, model=DL)
  assert_true((n.standard_error - (4.0 / 3.0).sqrt()).abs() < 1.0e-10)
  assert_true(h.confidence.lower < n.confidence.lower)
  assert_true(h.prediction is Some(_))
  let two = analyze([s[0], s[1]])
  assert_true(two.prediction is None)
  let f = analyze(s, model=Fixed, inference=Normal)
  assert_true(f.prediction is None)
  let invalid = try {
    ignore(analyze(s, model=Fixed))
    false
  } catch {
    _ => true
  }
  assert_true(invalid)
}
