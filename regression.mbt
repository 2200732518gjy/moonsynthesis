///|
/// Coefficient uncertainty uses the chosen normal or conservative modified-HK
/// scale. The covariance matrix below already includes that scale factor.
#derive(ToJson)
pub(all) struct Coefficient {
  name : String
  estimate : Double
  standard_error : Double
  confidence : Interval
}

///|
pub extend Coefficient with ToJson::{to_json}

///|
/// A fitted study-level model with an implicit intercept. Private construction
/// prevents invalid fitted objects from reaching the prediction operation.
#derive(ToJson)
pub struct Regression {
  model : Model
  count : Int32
  residual_df : Int32
  tau2 : Double
  residual_q : Double
  residual_heterogeneity_q : Double
  iterations : Int32
  inference : Inference
  alpha : Double
  coefficients : Array[Coefficient]
  covariance : Array[Array[Double]]
}

///|
pub extend Regression with ToJson::{to_json}

///|
pub fn Regression::tau2(self : Regression) -> Double {
  self.tau2
}

///|
pub fn Regression::coefficients(self : Regression) -> Array[Coefficient] {
  self.coefficients.copy()
}

///|
pub fn Regression::residual_df(self : Regression) -> Int32 {
  self.residual_df
}

///|
/// Fit independent aggregate effects with 0..8 numeric moderators, always an
/// intercept, k > p and k <= 512. Rows align with study order. Categorical
/// moderators must be explicitly dummy coded with one reference level omitted.
pub fn meta_regression(
  studies : Array[Study],
  moderators : Array[Array[Double]],
  names : Array[String],
  inference~ : Inference = ModifiedHK,
  alpha~ : Double = 0.05,
) -> Regression raise SynthesisError {
  validate_studies(studies, 2)
  require_alpha(alpha)
  let k = studies.length()
  let m = names.length()
  let p = m + 1
  if m > 8 || k <= p || moderators.length() != k {
    raise Invalid(
      "regression requires 0..8 moderators, k > p, and one row per study",
    )
  }
  for j in 0..<m {
    if names[j].trim().length() == 0 ||
      names[j].length() > 128 ||
      names[j] == "intercept" {
      raise Invalid("invalid moderator name")
    }
    for l in 0..<j {
      if names[l] == names[j] {
        raise Invalid("duplicate moderator name")
      }
    }
  }
  for row in moderators {
    if row.length() != m {
      raise Invalid("moderator row width differs from names")
    }
    for a in row {
      require_finite(a, "moderator")
    }
  }
  let center = zeros(m)
  let scale = zeros(m)
  for j in 0..<m {
    let mut lo = moderators[0][j]
    let mut hi = lo
    for row in moderators {
      lo = lo.min(row[j])
      hi = hi.max(row[j])
    }
    center[j] = lo / 2.0 + hi / 2.0
    scale[j] = (hi - center[j]).abs().max((lo - center[j]).abs())
    require_finite(scale[j], "moderator range")
    if scale[j] <= 0.0 {
      raise Invalid("constant moderator duplicates intercept")
    }
  }
  let x = Array::makei(k, i => {
    Array::makei(p, j => {
      if j == 0 {
        1.0
      } else {
        (moderators[i][j - 1] - center[j - 1]) / scale[j - 1]
      }
    })
  })
  let mut vscale = studies[0].variance
  for s in studies {
    vscale = vscale.min(s.variance)
  }
  let yscale = vscale.sqrt()
  let origin = studies[0].effect
  let y = Array::makei(k, i => (studies[i].effect - origin) / yscale)
  let v = Array::makei(k, i => studies[i].variance / vscale)
  for i in 0..<k {
    require_finite(y[i], "scaled effect")
    require_finite(v[i], "scaled variance")
  }
  let residual_heterogeneity_q = weighted_qr(x, y, v, 0.0).residual_q
  let (tau, fit, iterations) = solve_reml(x, y, v)
  let tau2 = tau * vscale
  require_finite(tau2, "REML tau2")
  let df = k - p
  let factor = match inference {
    Normal => 1.0
    ModifiedHK => (fit.residual_q / df.to_double()).max(1.0)
  }
  let critical = match inference {
    Normal => normal_critical(alpha)
    ModifiedHK => student_critical(alpha, df)
  }
  // Back-transform the centered/scaled design and effect units.
  let transform = Array::makei(p, _ => zeros(p))
  transform[0][0] = yscale
  for j in 1..<p {
    transform[j][j] = yscale / scale[j - 1]
    transform[0][j] = -center[j - 1] * transform[j][j]
  }
  let estimates = zeros(p)
  let covariance = Array::makei(p, _ => zeros(p))
  for j in 0..<p {
    for h in 0..<p {
      estimates[j] = estimates[j] + transform[j][h] * fit.beta[h]
    }
    if j == 0 {
      estimates[j] = estimates[j] + origin
    }
    require_finite(estimates[j], "coefficient estimate")
    for l in 0..<p {
      for a in 0..<p {
        for b in 0..<p {
          covariance[j][l] = covariance[j][l] +
            transform[j][a] * fit.covariance[a][b] * transform[l][b] * factor
        }
      }
      require_finite(covariance[j][l], "coefficient covariance")
    }
  }
  let coefficients : Array[Coefficient] = []
  for j in 0..<p {
    if covariance[j][j] <= 0.0 {
      raise Invalid("coefficient variance underflow or cancellation")
    }
    let standard_error = covariance[j][j].sqrt()
    coefficients.push({
      name: if j == 0 {
        "intercept"
      } else {
        names[j - 1]
      },
      estimate: estimates[j],
      standard_error,
      confidence: centered_interval(estimates[j], critical * standard_error),
    })
  }
  {
    model: REML,
    count: k,
    residual_df: df,
    tau2,
    residual_q: fit.residual_q,
    residual_heterogeneity_q,
    iterations,
    inference,
    alpha,
    coefficients,
    covariance,
  }
}

///|
#derive(ToJson)
pub(all) struct RegressionPrediction {
  estimate : Double
  standard_error : Double
  confidence : Interval
  prediction : Interval?
}

///|
pub extend RegressionPrediction with ToJson::{to_json}

///|
/// Predict on the additive effect scale. Confidence describes the mean;
/// prediction adds residual heterogeneity for a new independent true effect.
/// Approximate prediction t intervals use k-p-1 df and are absent if df <= 1.
pub fn Regression::predict(
  self : Regression,
  moderators : Array[Double],
) -> RegressionPrediction raise SynthesisError {
  let p = self.coefficients.length()
  if moderators.length() != p - 1 {
    raise Invalid("prediction row width differs from fitted model")
  }
  for a in moderators {
    require_finite(a, "prediction moderator")
  }
  let x = Array::makei(p, j => if j == 0 { 1.0 } else { moderators[j - 1] })
  let mut estimate = 0.0
  let mut variance = 0.0
  for j in 0..<p {
    estimate = estimate + x[j] * self.coefficients[j].estimate
    for l in 0..<p {
      variance = variance + x[j] * self.covariance[j][l] * x[l]
    }
  }
  require_finite(estimate, "predicted mean")
  require_finite(variance, "prediction mean variance")
  if variance <= 0.0 {
    raise Invalid("prediction mean variance underflow or cancellation")
  }
  let standard_error = variance.sqrt()
  let critical = match self.inference {
    Normal => normal_critical(self.alpha)
    ModifiedHK => student_critical(self.alpha, self.residual_df)
  }
  let confidence = centered_interval(estimate, critical * standard_error)
  let prediction = if self.residual_df <= 1 {
    None
  } else {
    Some(
      centered_interval(
        estimate,
        student_critical(self.alpha, self.residual_df - 1) *
        (self.tau2 + variance).sqrt(),
      ),
    )
  }
  { estimate, standard_error, confidence, prediction, }
}

///|
/// Intercept-only REML uses exactly the regression variance-component engine.
pub fn tau_reml(studies : Array[Study]) -> Double raise SynthesisError {
  let fit = meta_regression(
    studies,
    Array::makei(studies.length(), _ => []),
    [],
    inference=Normal,
  )
  fit.tau2
}

///|
pub fn random_reml(studies : Array[Study]) -> Pool raise SynthesisError {
  pool_at(studies, tau_reml(studies))
}
