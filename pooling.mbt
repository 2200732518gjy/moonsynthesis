///|
/// Point estimates, uncertainty and normalized weights; no mutable state escapes.
#derive(ToJson)
pub struct Pool {
  estimate : Double
  variance : Double
  weights : Array[Double]
  tau2 : Double
  residual_q : Double
}

///|
pub extend Pool with ToJson::{to_json}

///|
pub fn Pool::estimate(self : Pool) -> Double {
  self.estimate
}

///|
pub fn Pool::variance(self : Pool) -> Double {
  self.variance
}

///|
pub fn Pool::weights(self : Pool) -> Array[Double] {
  self.weights.copy()
}

///|
pub fn Pool::tau2(self : Pool) -> Double {
  self.tau2
}

///|
pub fn Pool::residual_q(self : Pool) -> Double {
  self.residual_q
}

///|
/// Scale weights by the smallest total variance to avoid overflow in 1/v.
pub fn pool_at(
  studies : Array[Study],
  tau2 : Double,
) -> Pool raise SynthesisError {
  validate_studies(studies, 2)
  require_finite(tau2, "tau2")
  if tau2 < 0.0 {
    raise Invalid("tau2 must be nonnegative")
  }
  let mut scale = studies[0].variance + tau2
  require_finite(scale, "total variance")
  for s in studies {
    scale = scale.min(s.variance + tau2)
  }
  let weights : Array[Double] = []
  let mut sum = 0.0
  let mut numerator = 0.0
  for s in studies {
    let total = s.variance + tau2
    require_finite(total, "total variance")
    let w = scale / total
    weights.push(w)
    sum = sum + w
    numerator = numerator + w * s.effect
  }
  let estimate = numerator / sum
  let variance = scale / sum
  require_finite(estimate, "pooled estimate")
  if variance <= 0.0 {
    raise Invalid("pooled variance underflow")
  }
  require_finite(variance, "pooled variance")
  let mut q = 0.0
  for i in 0..<studies.length() {
    weights[i] = weights[i] / sum
    let residual = (studies[i].effect - estimate) /
      (studies[i].variance + tau2).sqrt()
    q = q + residual * residual
  }
  require_finite(q, "residual Q")
  { estimate, variance, weights, tau2, residual_q: q, }
}

///|
/// Fixed effect inference assumes one shared true effect.
pub fn fixed(studies : Array[Study]) -> Pool raise SynthesisError {
  pool_at(studies, 0.0)
}
