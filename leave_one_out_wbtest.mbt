test "deletion refits and preserves order and original data" {
  let s = [study("a", 0.0, 1.0), study("b", 1.0, 1.0), study("c", 8.0, 1.0)]
  let d = leave_one_out(s)
  assert_eq(d.length(), 3)
  assert_eq(d[2].omitted_id, "c")
  assert_true((d[2].analysis.pool.estimate - 0.5).abs() < 1.0e-12)
  assert_eq(d[2].analysis.pool.tau2, 0.0)
  assert_eq(s[2].effect, 8.0)
  let bad = try { ignore(leave_one_out([s[0], s[1]])); false } catch { _ => true }
  assert_true(bad)
}
