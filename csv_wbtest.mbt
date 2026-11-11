///|
test "CSV labels escape quotes newlines and formula prefixes" {
  let s = [
    study(" =SUM(1,2)", 1.0, 1.0, group="x\"y"),
    study("line\nbreak", 2.0, 1.0),
  ]
  let csv = render_csv(s)
  assert_true(csv.contains("\"' =SUM(1,2)\""))
  assert_true(csv.contains("\"x\"\"y\""))
  assert_true(csv.contains("\"line\nbreak\""))
  assert_true(csv.contains("\r\n\"pooled\""))
  assert_eq(csv_text("-cmd"), "\"'-cmd\"")
  assert_eq(csv_number(-2.0), "\"-2\"")
}
