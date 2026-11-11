///|
test "cumulative prefixes begin at two and finish at the full model" {
  let s = [
    study("2021", 1.0, 1.0),
    study("2022", 3.0, 1.0),
    study("2023", 2.0, 1.0),
  ]
  let x = cumulative(s)
  assert_eq(x.length(), 2)
  assert_eq(x[0].through_id, "2022")
  assert_eq(x[0].analysis.count, 2)
  assert_eq(x[1].analysis.pool.estimate, analyze(s).pool.estimate)
}
