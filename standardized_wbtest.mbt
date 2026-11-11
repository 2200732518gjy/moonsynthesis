///|
test "Hedges g applies finite sample correction and symmetric variance" {
  let a : Arm = { n: 20, mean: 3.0, sd: 2.0, }
  let b : Arm = { n: 20, mean: 1.0, sd: 2.0, }
  let x = hedges_g("g", a, b)
  let j = 1.0 - 3.0 / 151.0
  assert_true((x.effect - j).abs() < 1.0e-12)
  assert_true((x.variance - (0.1 + j * j / 80.0)).abs() < 1.0e-12)
  let y = hedges_g("r", b, a)
  assert_eq(y.effect, -x.effect)
  assert_eq(y.variance, x.variance)
  let bad = try {
    ignore(
      hedges_g("bad", { n: 2, mean: 1.0, sd: 0.0, }, {
        n: 2,
        mean: 2.0,
        sd: 0.0,
      }),
    )
    false
  } catch {
    _ => true
  }
  assert_true(bad)
}
