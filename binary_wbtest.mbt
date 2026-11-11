test "binary log ratios and explicit correction" {
  let t : BinaryArm = { events: 10, total: 100 }
  let c : BinaryArm = { events: 20, total: 100 }
  let rr = log_risk_ratio("rr", t, c)
  assert_true((rr.effect - @math.ln(0.5)).abs() < 1.0e-12)
  assert_true((rr.variance - 0.13).abs() < 1.0e-12)
  let odds = log_odds_ratio("or", t, c)
  assert_true((odds.effect - @math.ln(4.0 / 9.0)).abs() < 1.0e-12)
  let zero : BinaryArm = { events: 0, total: 100 }
  let bad = try { ignore(log_risk_ratio("bad", zero, c)); false } catch { _ => true }
  assert_true(bad)
  assert_true(log_risk_ratio("ok", zero, c, correction=HalfIfZero).variance > 0.0)
  let double = try { ignore(log_odds_ratio("bad", zero, zero, correction=HalfIfZero)); false } catch { _ => true }
  assert_true(double)
}
