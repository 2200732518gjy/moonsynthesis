///|
/// Descriptive study-level results on the input effect scale.
/// Residuals below are standardized by sqrt(v+tau²), not externally studentized.
pub(all) struct StudySummary {
  id : String
  group : String
  effect : Double
  variance : Double
  confidence : Interval
  weight : Double
  residual : Double
  q_contribution : Double
} derive(ToJson)

///|
pub extend StudySummary with ToJson::{to_json}

///|
/// Recompute from input and options to prevent mixing weights from another fit.
/// Individual confidence intervals always use normal sampling uncertainty v_i;
/// neither the pooled HK adjustment nor tau² is a study measurement variance.
pub fn summarize_studies(
  studies : Array[Study],
  model~ : Model = PM,
  inference~ : Inference = ModifiedHK,
  alpha~ : Double = 0.05,
) -> Array[StudySummary] raise SynthesisError {
  let analysis = analyze(studies, model~, inference~, alpha~)
  let z = normal_critical(alpha)
  let output : Array[StudySummary] = []
  for i in 0..<studies.length() {
    let s = studies[i]
    let residual = (s.effect - analysis.pool.estimate) /
      (s.variance + analysis.pool.tau2).sqrt()
    output.push({
      id: s.id,
      group: s.group,
      effect: s.effect,
      variance: s.variance,
      confidence: centered_interval(s.effect, z * s.variance.sqrt()),
      weight: analysis.pool.weights[i],
      residual,
      q_contribution: residual * residual,
    })
  }
  output
}

///|
/// Present a log-scale interval as a ratio only by explicit caller request.
/// Overflow and underflow to zero are rejected; no effect family is inferred.
pub fn exponentiate_interval(
  interval : Interval,
) -> Interval raise SynthesisError {
  require_finite(interval.lower, "lower endpoint")
  require_finite(interval.upper, "upper endpoint")
  if interval.lower > interval.upper {
    raise Invalid("interval endpoints inverted")
  }
  let lower = @math.exp(interval.lower)
  let upper = @math.exp(interval.upper)
  require_finite(lower, "ratio lower endpoint")
  require_finite(upper, "ratio upper endpoint")
  if lower <= 0.0 {
    raise Invalid("ratio endpoint underflow")
  }
  { lower, upper, }
}
