///| Subgroup summaries retain labels in first-appearance order.
pub(all) struct Subgroup {
  label : String
  analysis : Analysis
} derive(ToJson)
pub extend Subgroup with ToJson::{to_json}

///| The between-group Q identity uses fixed weights in every component.
/// It is descriptive; no multiplicity-adjusted or interaction p-value is claimed.
pub(all) struct GroupComparison {
  groups : Array[Subgroup]
  between_q : Double
  between_df : Int
  within_q : Double
} derive(ToJson)
pub extend GroupComparison with ToJson::{to_json}

///| At least two groups, each with two studies, are required. Empty labels and
/// singleton groups are rejected rather than silently excluded from inference.
pub fn subgroups(studies : Array[Study], model~ : Model = PM,
  inference~ : Inference = ModifiedHK, alpha~ : Double = 0.05) -> GroupComparison raise SynthesisError {
  validate_studies(studies, 4)
  let labels : Array[String] = []
  for s in studies {
    if s.group.trim().length() == 0 { raise Invalid("subgroup labels must be nonempty") }
    let mut exists = false
    for label in labels { if s.group == label { exists = true } }
    if !exists { labels.push(s.group) }
  }
  if labels.length() < 2 { raise Invalid("subgroup comparison requires at least two groups") }
  let groups : Array[Subgroup] = []
  let mut within_q = 0.0
  for label in labels {
    let members : Array[Study] = []
    for s in studies { if s.group == label { members.push(s) } }
    validate_studies(members, 2)
    within_q = within_q + fixed(members).residual_q
    groups.push({ label, analysis: analyze(members, model~, inference~, alpha~) })
  }
  let between_q = (fixed(studies).residual_q - within_q).max(0.0)
  { groups, between_q, between_df: labels.length() - 1, within_q }
}
