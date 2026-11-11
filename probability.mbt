///|
/// A normal tail approximation (absolute error below 8e-8).
fn normal_tail(x : Double) -> Double {
  let z = x.abs()
  let t = 1.0 / (1.0 + 0.2316419 * z)
  let poly = t *
    (
      0.319381530 +
      t *
      (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429)))
    )
  let p = 0.3989422804014327 * @math.exp(-0.5 * z * z) * poly
  if x >= 0.0 {
    p
  } else {
    1.0 - p
  }
}

///|
/// Invert a monotone tail without a fragile closed-form extreme-tail fit.
pub fn normal_critical(alpha : Double) -> Double raise SynthesisError {
  require_alpha(alpha)
  let target = alpha / 2.0
  let mut low = 0.0
  let mut high = 8.0
  for _ in 0..<80 {
    let mid = (low + high) / 2.0
    if normal_tail(mid) > target {
      low = mid
    } else {
      high = mid
    }
  }
  (low + high) / 2.0
}

///|
fn require_alpha(alpha : Double) -> Unit raise SynthesisError {
  require_finite(alpha, "alpha")
  if alpha < 0.0001 || alpha > 0.5 {
    raise Invalid("alpha must be in [0.0001,0.5]")
  }
}

///|
/// Lanczos log-gamma for positive arguments; coefficients are mathematical constants.
fn log_gamma(z : Double) -> Double {
  let c = [
    676.5203681218851, -1259.1392167224028, 771.32342877765313, -176.61502916214059,
    12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7,
  ]
  let zz = z - 1.0
  let mut x = 0.99999999999980993
  for i in 0..<c.length() {
    x = x + c[i] / (zz + i.to_double() + 1.0)
  }
  let t = zz + 7.5
  0.9189385332046727 + (zz + 0.5) * @math.ln(t) - t + @math.ln(x)
}

///|
/// Modified Lentz continued fraction for the incomplete beta function.
fn beta_fraction(a : Double, b : Double, x : Double) -> Double {
  let qab = a + b
  let qap = a + 1.0
  let qam = a - 1.0
  let tiny = 1.0e-300
  let mut c = 1.0
  let mut d = 1.0 - qab * x / qap
  if d.abs() < tiny {
    d = tiny
  }
  d = 1.0 / d
  let mut h = d
  for m in 1..<401 {
    let md = m.to_double()
    let m2 = 2.0 * md
    let mut aa = md * (b - md) * x / ((qam + m2) * (a + m2))
    d = 1.0 + aa * d
    if d.abs() < tiny {
      d = tiny
    }
    c = 1.0 + aa / c
    if c.abs() < tiny {
      c = tiny
    }
    d = 1.0 / d
    h = h * d * c
    aa = -(a + md) * (qab + md) * x / ((a + m2) * (qap + m2))
    d = 1.0 + aa * d
    if d.abs() < tiny {
      d = tiny
    }
    c = 1.0 + aa / c
    if c.abs() < tiny {
      c = tiny
    }
    d = 1.0 / d
    let delta = d * c
    h = h * delta
    if (delta - 1.0).abs() < 3.0e-14 {
      break
    }
  }
  h
}

///|
fn regularized_beta(a : Double, b : Double, x : Double) -> Double {
  if x <= 0.0 {
    return 0.0
  }
  if x >= 1.0 {
    return 1.0
  }
  let bt = @math.exp(
    log_gamma(a + b) -
    log_gamma(a) -
    log_gamma(b) +
    a * @math.ln(x) +
    b * @math.ln(1.0 - x),
  )
  if x < (a + 1.0) / (a + b + 2.0) {
    bt * beta_fraction(a, b, x) / a
  } else {
    1.0 - bt * beta_fraction(b, a, 1.0 - x) / b
  }
}

///|
/// Student t upper-tail critical value for a two-sided confidence level.
pub fn student_critical(
  alpha : Double,
  df : Int32,
) -> Double raise SynthesisError {
  require_alpha(alpha)
  if df < 1 || df > 10000 {
    raise Invalid("degrees of freedom must be 1..10000")
  }
  let nu = df.to_double()
  let mut low = 0.0
  let mut high = 10000.0
  for _ in 0..<90 {
    let mid = (low + high) / 2.0
    let p = regularized_beta(nu / 2.0, 0.5, nu / (nu + mid * mid))
    if p > alpha {
      low = mid
    } else {
      high = mid
    }
  }
  (low + high) / 2.0
}
