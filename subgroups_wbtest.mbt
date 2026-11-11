test "fixed subgroup Q decomposes and singleton groups fail" {
  let s = [study("a", 0.0, 1.0, group="low"), study("b", 2.0, 1.0, group="low"),
    study("c", 4.0, 1.0, group="high"), study("d", 6.0, 1.0, group="high")]
  let x = subgroups(s)
  assert_eq(x.groups.length(), 2)
  assert_eq(x.groups[0].label, "low")
  assert_true((x.within_q + x.between_q - heterogeneity(s).q).abs() < 1.0e-10)
  assert_true((x.between_q - 16.0).abs() < 1.0e-10)
  let bad = try { ignore(subgroups([s[0], s[1], s[2], study("e", 5.0, 1.0, group="third")])); false } catch { _ => true }
  assert_true(bad)
}
