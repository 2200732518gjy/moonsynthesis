///|
/// Acklam's rational inverse-normal approximation on the supported alpha domain.
/// Coefficients are numerical constants, evaluated here in Horner form.
/// Unlike a low-order CDF inversion this keeps tail quantile error small.
pub fn normal_critical(alpha : Double) -> Double raise SynthesisError {
  require_alpha(alpha)
  let p = alpha / 2.0
  if p < 0.02425 {
    let q = (-2.0 * @math.ln(p)).sqrt()
    let numerator = (
        (
          (
            (-0.007784894002430293 * q - 0.3223964580411365) * q -
            2.400758277161838
          ) *
          q -
          2.549732539343734
        ) *
        q +
        4.374664141464968
      ) *
      q +
      2.938163982698783
    let denominator = (
        (
          (0.007784695709041462 * q + 0.3224671290700398) * q +
          2.445134137142996
        ) *
        q +
        3.754408661907416
      ) *
      q +
      1.0
    -numerator / denominator
  } else {
    let q = p - 0.5
    let r = q * q
    let numerator = (
        (
          (
            (
              (-39.69683028665376 * r + 220.9460984245205) * r -
              275.9285104469687
            ) *
            r +
            138.3577518672690
          ) *
          r -
          30.66479806614716
        ) *
        r +
        2.506628277459239
      ) *
      q
    let denominator = (
        (
          ((-54.47609879822406 * r + 161.5858368580409) * r - 155.6989798598866) *
          r +
          66.80131188771972
        ) *
        r -
        13.28068155288572
      ) *
      r +
      1.0
    -numerator / denominator
  }
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
