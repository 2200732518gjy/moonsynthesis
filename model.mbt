///|
/// An invalid dataset or numerically unrepresentable result is explicit.
pub suberror SynthesisError {
  Invalid(String)
}

///|
/// A study carries an effect on an additive analysis scale and its variance.
/// All construction and extraction copy mutable arrays at API boundaries.
pub struct Study {
  id : String
  effect : Double
  variance : Double
  group : String
} derive(ToJson)

///|
pub extend Study with ToJson::{to_json}

///|
/// Reject NaN, infinities, zero variances and excessive data up front.
fn require_finite(x : Double, label : String) -> Unit raise SynthesisError {
  if x.is_nan() || x.is_inf() {
    raise Invalid(label + " must be finite")
  }
}

///|
pub fn study(
  id : String,
  effect : Double,
  variance : Double,
  group~ : String = "",
) -> Study raise SynthesisError {
  if id.trim().length() == 0 || id.length() > 256 {
    raise Invalid("study id length must be 1..256")
  }
  if group.length() > 256 {
    raise Invalid("group label exceeds 256 characters")
  }
  require_finite(effect, "effect")
  require_finite(variance, "variance")
  if variance <= 0.0 {
    raise Invalid("variance must be positive")
  }
  { id, effect, variance, group, }
}

///|
pub fn Study::id(self : Study) -> String {
  self.id
}

///|
pub fn Study::effect(self : Study) -> Double {
  self.effect
}

///|
pub fn Study::variance(self : Study) -> Double {
  self.variance
}

///|
pub fn Study::group(self : Study) -> String {
  self.group
}

///|
pub fn validate_studies(
  studies : Array[Study],
  minimum : Int32,
) -> Unit raise SynthesisError {
  if studies.length() < minimum || studies.length() > 512 {
    raise Invalid("study count outside supported 2..512 range")
  }
  for i in 0..<studies.length() {
    let x = studies[i]
    ignore(study(x.id, x.effect, x.variance, group=x.group))
    for j in 0..<i {
      if studies[j].id == x.id {
        raise Invalid("duplicate study id: " + x.id)
      }
    }
  }
}
