///|
/// Bracket and bisect Q(tau²)=k-1. Relative stopping avoids false zero roots.
/// The monotone equation is solved from fresh inverse-variance weights each time.
pub fn tau_pm(studies : Array[Study]) -> Double raise SynthesisError {
  let p = fixed(studies)
  let target = (studies.length() - 1).to_double()
  if p.residual_q <= target {
    return 0.0
  }
  let mut high = studies[0].variance
  for s in studies {
    high = high.max(s.variance)
  }
  high = high.max(tau_dl(studies))
  let mut bracketed = false
  for _ in 0..<1024 {
    if pool_at(studies, high).residual_q <= target {
      bracketed = true
      break
    }
    high = high * 2.0
    require_finite(high, "PM bracket")
  }
  if !bracketed {
    raise Invalid("PM root could not be bracketed")
  }
  let mut low = 0.0
  for _ in 0..<160 {
    let mid = low + (high - low) / 2.0
    if mid == low || mid == high {
      break
    }
    let q = pool_at(studies, mid).residual_q
    if q > target {
      low = mid
    } else {
      high = mid
    }
  }
  let tau = low + (high - low) / 2.0
  require_finite(tau, "PM tau2")
  tau
}

///|
pub fn random_pm(studies : Array[Study]) -> Pool raise SynthesisError {
  pool_at(studies, tau_pm(studies))
}
