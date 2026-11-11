///| DerSimonian-Laird method-of-moments estimate, truncated at zero.
pub fn tau_dl(studies : Array[Study]) -> Double raise SynthesisError {
  let p = fixed(studies)
  let excess = p.residual_q - (studies.length() - 1).to_double()
  if excess <= 0.0 { return 0.0 }
  let mut scale = studies[0].variance
  for s in studies { scale = scale.min(s.variance) }
  let mut sum = 0.0
  let mut squares = 0.0
  for s in studies {
    let w = scale / s.variance
    sum = sum + w
    squares = squares + w * w
  }
  let denominator = sum - squares / sum
  if denominator <= 0.0 { raise Invalid("effective study weights degenerate") }
  let tau = (excess / denominator) * scale
  require_finite(tau, "DL tau2")
  tau
}

///|
pub fn random_dl(studies : Array[Study]) -> Pool raise SynthesisError {
  pool_at(studies, tau_dl(studies))
}
