///|
/// Choices are explicit so a random-effects result cannot be mislabeled fixed.
pub(all) enum Model {
  Fixed
  DL
  PM
} derive(Eq, ToJson)

///|
pub extend Model with Eq::{not_equal, equal}

///|
pub extend Model with ToJson::{to_json}

///|
/// Normal uses z and inverse total precision. ModifiedHK uses t(k-1)
/// and max(1, residual Q/(k-1)); this conservative choice is not raw HKSJ.
pub(all) enum Inference {
  Normal
  ModifiedHK
} derive(Eq, ToJson)

///|
pub extend Inference with Eq::{not_equal, equal}

///|
pub extend Inference with ToJson::{to_json}

///|
/// Closed, finite interval on the same additive scale as the input effects.
pub(all) struct Interval {
  lower : Double
  upper : Double
} derive(ToJson)

///|
pub extend Interval with ToJson::{to_json}

///|
/// A model fit records every choice needed to interpret its uncertainty.
pub(all) struct Analysis {
  model : Model
  inference : Inference
  alpha : Double
  count : Int32
  pool : Pool
  heterogeneity : Heterogeneity
  standard_error : Double
  confidence : Interval
  prediction : Interval?
} derive(ToJson)

///|
pub extend Analysis with ToJson::{to_json}

///|
/// Validate endpoints instead of serializing infinite or inverted intervals.
fn centered_interval(
  center : Double,
  radius : Double,
) -> Interval raise SynthesisError {
  require_finite(radius, "interval radius")
  let lower = center - radius
  let upper = center + radius
  require_finite(lower, "interval lower endpoint")
  require_finite(upper, "interval upper endpoint")
  if radius < 0.0 {
    raise Invalid("negative interval radius")
  }
  { lower, upper, }
}

///|
/// Fit independent aggregate effects. Prediction is absent for fixed models
/// and for two-study random models, where k-2 degrees of freedom is unavailable.
pub fn analyze(
  studies : Array[Study],
  model~ : Model = PM,
  inference~ : Inference = ModifiedHK,
  alpha~ : Double = 0.05,
) -> Analysis raise SynthesisError {
  require_alpha(alpha)
  let pool = match model {
    Fixed => fixed(studies)
    DL => random_dl(studies)
    PM => random_pm(studies)
  }
  if model == Fixed && inference == ModifiedHK {
    raise Invalid("fixed model requires normal inference")
  }
  let count = studies.length()
  let h = heterogeneity(studies)
  let factor = match inference {
    Normal => 1.0
    ModifiedHK => (pool.residual_q / (count - 1).to_double()).max(1.0)
  }
  let standard_error = (pool.variance * factor).sqrt()
  require_finite(standard_error, "standard error")
  let critical = match inference {
    Normal => normal_critical(alpha)
    ModifiedHK => student_critical(alpha, count - 1)
  }
  let confidence = centered_interval(pool.estimate, critical * standard_error)
  let prediction = if model == Fixed || count < 3 {
    None
  } else {
    // Conventional approximate t(k-2) predictive interval for a new true effect.
    let radius = student_critical(alpha, count - 2) *
      (pool.tau2 + standard_error * standard_error).sqrt()
    Some(centered_interval(pool.estimate, radius))
  }
  {
    model,
    inference,
    alpha,
    count,
    pool,
    heterogeneity: h,
    standard_error,
    confidence,
    prediction,
  }
}
