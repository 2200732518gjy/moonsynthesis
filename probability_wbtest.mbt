test "normal and student reference quantiles" {
  assert_true((normal_critical(0.05) - 1.959963984540054).abs() < 2.0e-6)
  assert_true((student_critical(0.05, 1) - 12.706204736).abs() < 1.0e-7)
  assert_true((student_critical(0.05, 10) - 2.228138852).abs() < 1.0e-8)
  assert_true((student_critical(0.01, 30) - 2.749995654).abs() < 1.0e-8)
}
test "probability domain validation" {
  for x in [0.0, -0.1, 0.9, 0.0 / 0.0] {
    assert_true(try { ignore(normal_critical(x)); false } catch { _ => true })
  }
  assert_true(try { ignore(student_critical(0.05, 0)); false } catch { _ => true })
}
