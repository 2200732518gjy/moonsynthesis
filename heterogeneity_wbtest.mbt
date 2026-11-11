test "Cochran heterogeneity and homogeneous clamp" {
  let h = heterogeneity([study("a", 1.0, 1.0), study("b", 3.0, 1.0)])
  assert_eq(h.q(), 2.0)
  assert_eq(h.df(), 1)
  assert_eq(h.i2(), 0.5)
  assert_eq(h.h2(), 2.0)
  let h = heterogeneity([study("a", 2.0, 0.1), study("b", 2.0, 0.1)])
  assert_eq(h.i2(), 0.0)
  assert_eq(h.h2(), 0.0)
}
