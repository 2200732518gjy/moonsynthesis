///|
/// Q, I-squared (fraction) and H-squared use fixed inverse variance weights.
pub struct Heterogeneity {
  q : Double
  df : Int32
  i2 : Double
  h2 : Double
} derive(ToJson)

///|
pub extend Heterogeneity with ToJson::{to_json}

///|
pub fn Heterogeneity::q(self : Heterogeneity) -> Double {
  self.q
}

///|
pub fn Heterogeneity::df(self : Heterogeneity) -> Int32 {
  self.df
}

///|
pub fn Heterogeneity::i2(self : Heterogeneity) -> Double {
  self.i2
}

///|
pub fn Heterogeneity::h2(self : Heterogeneity) -> Double {
  self.h2
}

///|
/// Homogeneous studies have I²=0; never divide by zero Q.
pub fn heterogeneity(
  studies : Array[Study],
) -> Heterogeneity raise SynthesisError {
  let p = fixed(studies)
  let df = studies.length() - 1
  let q = p.residual_q
  let i2 = if q <= df.to_double() { 0.0 } else { 1.0 - df.to_double() / q }
  { q, df, i2, h2: q / df.to_double(), }
}
