///|
/// Summary of a continuous measurement arm, preserving sampling-unit counts.
pub(all) struct Arm {
  n : Int32
  mean : Double
  sd : Double
} derive(ToJson)

///|
pub extend Arm with ToJson::{to_json}

///|
/// Validate before arithmetic to avoid integer overflow or undefined SDs.
fn validate_arm(arm : Arm) -> Unit raise SynthesisError {
  if arm.n < 2 || arm.n > 100000000 {
    raise Invalid("arm n must be 2..100000000")
  }
  require_finite(arm.mean, "arm mean")
  require_finite(arm.sd, "arm sd")
  if arm.sd < 0.0 {
    raise Invalid("arm sd must be nonnegative")
  }
}

///|
/// Treatment minus control mean difference, for independent sampling arms.
pub fn mean_difference(
  id : String,
  treatment : Arm,
  control : Arm,
  group~ : String = "",
) -> Study raise SynthesisError {
  validate_arm(treatment)
  validate_arm(control)
  let effect = treatment.mean - control.mean
  let variance = treatment.sd * treatment.sd / treatment.n.to_double() +
    control.sd * control.sd / control.n.to_double()
  study(id, effect, variance, group~)
}
