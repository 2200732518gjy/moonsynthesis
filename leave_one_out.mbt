///|
/// A deletion result is a refit, including a fresh between-study variance.
#derive(ToJson)
pub(all) struct Deletion {
  omitted_id : String
  analysis : Analysis
  estimate_shift : Double
}

///|
pub extend Deletion with ToJson::{to_json}

///|
/// Return in original input order; input records are never changed.
/// The cost is quadratic in study count times the selected fitting cost.
pub fn leave_one_out(
  studies : Array[Study],
  model~ : Model = PM,
  inference~ : Inference = ModifiedHK,
  alpha~ : Double = 0.05,
) -> Array[Deletion] raise SynthesisError {
  validate_studies(studies, 3)
  if studies.length() > 64 {
    raise Invalid("refitting workflow exceeds 64 studies")
  }
  let baseline = analyze(studies, model~, inference~, alpha~)
  let output : Array[Deletion] = []
  for omitted in 0..<studies.length() {
    let subset : Array[Study] = []
    for i in 0..<studies.length() {
      if i != omitted {
        subset.push(studies[i])
      }
    }
    let analysis = analyze(subset, model~, inference~, alpha~)
    let estimate_shift = analysis.pool.estimate - baseline.pool.estimate
    require_finite(estimate_shift, "deletion shift")
    output.push({ omitted_id: studies[omitted].id, analysis, estimate_shift, })
  }
  output
}
