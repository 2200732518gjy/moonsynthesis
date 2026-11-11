test "mean difference keeps direction and sampling uncertainty" {
  let a : Arm = { n: 20, mean: 5.0, sd: 2.0 }
  let b : Arm = { n: 10, mean: 3.0, sd: 1.0 }
  let x = mean_difference("trial", a, b)
  assert_eq(x.effect, 2.0)
  assert_true((x.variance - 0.3).abs() < 1.0e-12)
  let reverse = mean_difference("reverse", b, a)
  assert_eq(reverse.effect, -2.0)
  assert_eq(reverse.variance, x.variance)
  let bad = try { ignore(mean_difference("bad", { n: 1, mean: 0.0, sd: 1.0 }, b)); false } catch { _ => true }
  assert_true(bad)
}
