///| Hedges g using J=1-3/(4df-1), a documented small-sample approximation.
/// The variance convention matches statsmodels effectsize_smd: N/(n1*n0)+g²/(2N).
/// All inputs must measure the same construct; the library cannot establish this.
pub fn hedges_g(id : String, treatment : Arm, control : Arm,
  group~ : String = "") -> Study raise SynthesisError {
  validate_arm(treatment)
  validate_arm(control)
  let nt = treatment.n.to_double()
  let nc = control.n.to_double()
  let df = nt + nc - 2.0
  let pooled = ((nt - 1.0) * treatment.sd * treatment.sd +
    (nc - 1.0) * control.sd * control.sd) / df
  require_finite(pooled, "pooled SD squared")
  if pooled <= 0.0 { raise Invalid("standardized difference requires positive pooled SD") }
  let j = 1.0 - 3.0 / (4.0 * df - 1.0)
  let effect = j * (treatment.mean - control.mean) / pooled.sqrt()
  let variance = (nt + nc) / (nt * nc) + effect * effect / (2.0 * (nt + nc))
  study(id, effect, variance, group~)
}
