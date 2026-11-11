test "DL exact equal variance moment solution" {
  let s = [study("a", 1.0, 1.0), study("b", 5.0, 1.0), study("c", 3.0, 1.0)]
  assert_true((tau_dl(s) - 3.0).abs() < 1.0e-12)
  assert_true((random_dl(s).variance() - 4.0 / 3.0).abs() < 1.0e-12)
}
test "DL truncates homogeneous data at zero" {
  assert_eq(tau_dl([study("a", 1.0, 1.0), study("b", 1.1, 1.0)]), 0.0)
}
