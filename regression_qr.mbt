///|
/// A weighted fit in dimensionless variance/effect and centered design units.
priv struct QrFit {
  beta : Array[Double]
  covariance : Array[Array[Double]]
  residual_q : Double
  score : Double
}

///|
fn zeros(n : Int32) -> Array[Double] {
  Array::make(n, 0.0)
}

///|
/// Modified Gram-Schmidt with a second orthogonalization pass. No normal
/// equations or unguarded inverse are used to estimate coefficients.
fn weighted_qr(
  x : Array[Array[Double]],
  y : Array[Double],
  v : Array[Double],
  tau : Double,
) -> QrFit raise SynthesisError {
  let k = y.length()
  let p = x[0].length()
  let q : Array[Array[Double]] = []
  let r = Array::makei(p, _ => zeros(p))
  let weights = Array::makei(k, i => 1.0 / (v[i] + tau))
  for j in 0..<p {
    let col = Array::makei(k, i => x[i][j] * weights[i].sqrt())
    let mut original = 0.0
    for a in col {
      original = original + a * a
    }
    for _pass in 0..<2 {
      for l in 0..<j {
        let mut dot = 0.0
        for i in 0..<k {
          dot = dot + q[l][i] * col[i]
        }
        r[l][j] = r[l][j] + dot
        for i in 0..<k {
          col[i] = col[i] - dot * q[l][i]
        }
      }
    }
    let mut norm = 0.0
    for a in col {
      norm = norm + a * a
    }
    norm = norm.sqrt()
    require_finite(norm, "weighted design norm")
    if norm <= 1.0e-10 * original.sqrt() || norm <= 0.0 {
      raise Invalid("rank deficient or ill-conditioned moderator design")
    }
    r[j][j] = norm
    for i in 0..<k {
      col[i] = col[i] / norm
    }
    q.push(col)
  }
  let beta = zeros(p)
  for j in 0..<p {
    for i in 0..<k {
      beta[j] = beta[j] + q[j][i] * weights[i].sqrt() * y[i]
    }
  }
  for rev in 0..<p {
    let j = p - 1 - rev
    for l in (j + 1)..<p {
      beta[j] = beta[j] - r[j][l] * beta[l]
    }
    beta[j] = beta[j] / r[j][j]
    require_finite(beta[j], "regression coefficient")
  }
  // Triangular solves yield R^-1, and hence (X'WX)^-1 = R^-1 R^-T.
  let inverse = Array::makei(p, _ => zeros(p))
  for col in 0..<p {
    for rev in 0..<p {
      let j = p - 1 - rev
      let mut a = if j == col { 1.0 } else { 0.0 }
      for l in (j + 1)..<p {
        a = a - r[j][l] * inverse[l][col]
      }
      inverse[j][col] = a / r[j][j]
    }
  }
  let covariance = Array::makei(p, _ => zeros(p))
  for j in 0..<p {
    for l in 0..<p {
      for h in 0..<p {
        covariance[j][l] = covariance[j][l] + inverse[j][h] * inverse[l][h]
      }
      require_finite(covariance[j][l], "regression covariance")
    }
  }
  let mut residual_q = 0.0
  let mut score = 0.0
  for i in 0..<k {
    let mut residual = y[i]
    let mut leverage = 0.0
    for j in 0..<p {
      residual = residual - x[i][j] * beta[j]
      leverage = leverage + q[j][i] * q[j][i]
    }
    residual_q = residual_q + weights[i] * residual * residual
    // 2*d log L_REML / d tau = y'P^2 y - tr(P).
    score = score +
      weights[i] * (weights[i] * residual * residual - (1.0 - leverage))
  }
  require_finite(residual_q, "regression residual Q")
  require_finite(score, "REML score")
  { beta, covariance, residual_q, score, }
}

///|
/// Bracket a regular REML score root from the variance-component boundary,
/// then bisect. Nonconvergence is an error, not a silently accepted estimate.
fn solve_reml(
  x : Array[Array[Double]],
  y : Array[Double],
  v : Array[Double],
) -> (Double, QrFit, Int32) raise SynthesisError {
  let at_zero = weighted_qr(x, y, v, 0.0)
  if at_zero.score <= 0.0 {
    return (0.0, at_zero, 0)
  }
  let mut high = 1.0
  let mut upper = weighted_qr(x, y, v, high)
  let mut iterations = 1
  while upper.score > 0.0 {
    if iterations >= 1024 {
      raise Invalid("REML failed to bracket variance component")
    }
    high = high * 2.0
    require_finite(high, "REML bracket")
    upper = weighted_qr(x, y, v, high)
    iterations = iterations + 1
  }
  let mut low = 0.0
  for _ in 0..<180 {
    let middle = low + (high - low) / 2.0
    let current = weighted_qr(x, y, v, middle)
    iterations = iterations + 1
    if current.score > 0.0 {
      low = middle
    } else {
      high = middle
    }
    if high - low <= 1.0e-12 * (1.0 + middle) {
      let tau = low + (high - low) / 2.0
      return (tau, weighted_qr(x, y, v, tau), iterations)
    }
  }
  raise Invalid("REML failed to converge")
}
