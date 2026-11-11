///| JSON arm summaries share the same validation as the typed API.
fn decode_arm(value : Json) -> Arm raise SynthesisError {
  let o = object_value(value, "arm")
  exact_keys(o, ["n", "mean", "sd"])
  let arm : Arm = {
    n: count_value(required(o, "n"), "n"),
    mean: number_value(required(o, "mean"), "mean"),
    sd: number_value(required(o, "sd"), "sd"),
  }
  validate_arm(arm)
  arm
}

///|
fn decode_binary_arm(value : Json) -> BinaryArm raise SynthesisError {
  let o = object_value(value, "binary arm")
  exact_keys(o, ["events", "total"])
  { events: count_value(required(o, "events"), "events"),
    total: count_value(required(o, "total"), "total") }
}

///| A request must use one effect family throughout; raw direct inputs are
/// deliberately a separate family because their units cannot be inferred.
fn study_kind(value : Json) -> String raise SynthesisError {
  optional_text(object_value(value, "study"), "kind", "direct")
}

///| Each form has its own field allowlist, so variance and SD cannot be confused.
fn decode_study(value : Json) -> Study raise SynthesisError {
  let o = object_value(value, "study")
  let kind = study_kind(value)
  if kind == "direct" {
    return direct_study(value)
  }
  if kind != "md" && kind != "hedges-g" && kind != "log-or" && kind != "log-rr" {
    raise Invalid("study kind must be direct, md, hedges-g, log-or or log-rr")
  }
  let id = text_value(required(o, "id"), "id")
  let group = optional_text(o, "group", "")
  if kind == "md" || kind == "hedges-g" {
    exact_keys(o, ["kind", "id", "group", "treatment", "control"])
    let treatment = decode_arm(required(o, "treatment"))
    let control = decode_arm(required(o, "control"))
    if kind == "md" {
      mean_difference(id, treatment, control, group~)
    } else {
      hedges_g(id, treatment, control, group~)
    }
  } else {
    exact_keys(o, ["kind", "id", "group", "treatment", "control", "correction"])
    let correction = match optional_text(o, "correction", "none") {
      "none" => NoCorrection
      "half-if-zero" => HalfIfZero
      _ => raise Invalid("correction must be none or half-if-zero")
    }
    let treatment = decode_binary_arm(required(o, "treatment"))
    let control = decode_binary_arm(required(o, "control"))
    if kind == "log-or" {
      log_odds_ratio(id, treatment, control, correction~, group~)
    } else {
      log_risk_ratio(id, treatment, control, correction~, group~)
    }
  }
}
