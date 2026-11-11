///| Counts refer to independent Bernoulli sampling arms, not paired outcomes.
pub(all) struct BinaryArm {
  events : Int
  total : Int
} derive(ToJson)
pub extend BinaryArm with ToJson::{to_json}

///| HalfIfZero adds one half to all four cells only when any cell is zero.
pub(all) enum Correction {
  NoCorrection
  HalfIfZero
} derive(Eq, ToJson)
pub extend Correction with Eq::{not_equal, equal}
pub extend Correction with ToJson::{to_json}

///| Return adjusted event/non-event cells after rejecting uninformative tables.
fn binary_cells(t : BinaryArm, c : BinaryArm, correction : Correction) -> (Double, Double, Double, Double) raise SynthesisError {
  for arm in [t, c] {
    if arm.total < 1 || arm.total > 100000000 || arm.events < 0 || arm.events > arm.total {
      raise Invalid("binary counts require 0 <= events <= total <= 100000000")
    }
  }
  if (t.events == 0 && c.events == 0) || (t.events == t.total && c.events == c.total) {
    raise Invalid("double-zero or double-all-event table has no supported contrast")
  }
  let mut a = t.events.to_double()
  let mut b = (t.total - t.events).to_double()
  let mut cc = c.events.to_double()
  let mut d = (c.total - c.events).to_double()
  if a == 0.0 || b == 0.0 || cc == 0.0 || d == 0.0 {
    if correction == NoCorrection { raise Invalid("zero cell requires explicit HalfIfZero correction") }
    a = a + 0.5
    b = b + 0.5
    cc = cc + 0.5
    d = d + 0.5
  }
  (a, b, cc, d)
}

///| Log odds ratio with the Woolf inverse-cell variance on adjusted cells.
pub fn log_odds_ratio(id : String, treatment : BinaryArm, control : BinaryArm,
  correction~ : Correction = NoCorrection, group~ : String = "") -> Study raise SynthesisError {
  let (a, b, c, d) = binary_cells(treatment, control, correction)
  let effect = @math.ln(a) + @math.ln(d) - @math.ln(b) - @math.ln(c)
  let variance = 1.0 / a + 1.0 / b + 1.0 / c + 1.0 / d
  study(id, effect, variance, group~)
}

///| Log risk ratio. Correction changes both denominators by one, deliberately.
pub fn log_risk_ratio(id : String, treatment : BinaryArm, control : BinaryArm,
  correction~ : Correction = NoCorrection, group~ : String = "") -> Study raise SynthesisError {
  let (a, b, c, d) = binary_cells(treatment, control, correction)
  let effect = @math.ln(a / (a + b)) - @math.ln(c / (c + d))
  let variance = 1.0 / a - 1.0 / (a + b) + 1.0 / c - 1.0 / (c + d)
  study(id, effect, variance, group~)
}
