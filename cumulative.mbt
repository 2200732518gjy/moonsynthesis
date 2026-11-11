///| Prefix endpoints refer to supplied order, which callers may sort by date.
pub(all) struct Cumulative {
  through_id : String
  analysis : Analysis
} derive(ToJson)
pub extend Cumulative with ToJson::{to_json}

///| Prefixes begin with two studies; no single-study pseudo-synthesis is emitted.
/// Each prefix re-estimates tau² and uncertainty using its own study count.
pub fn cumulative(studies : Array[Study], model~ : Model = PM,
  inference~ : Inference = ModifiedHK, alpha~ : Double = 0.05) -> Array[Cumulative] raise SynthesisError {
  validate_studies(studies, 2)
  let prefix : Array[Study] = [studies[0]]
  let output : Array[Cumulative] = []
  for i in 1..<studies.length() {
    prefix.push(studies[i])
    output.push({ through_id: studies[i].id, analysis: analyze(prefix, model~, inference~, alpha~) })
  }
  output
}
