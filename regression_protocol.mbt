///|
/// Protocol v2 adds regression without changing the public v1 Request record.
/// All work and predictions finish before any successful response is emitted.
fn execute_model_text(text : String) -> Json raise SynthesisError {
  if text.length() > 1048576 {
    raise Invalid("request exceeds 1048576 UTF-16 code units")
  }
  let value = @json.parse(
    text,
    max_nesting_depth=16,
    reject_duplicate_keys=true,
  ) catch {
    _ => raise Invalid("invalid JSON, duplicate key, or excessive nesting")
  }
  let o = object_value(value, "request")
  let version = count_value(required(o, "version"), "version")
  if version != 2 {
    return execute(parse_request(text))
  }
  exact_keys(o, [
    "version", "model", "inference", "alpha", "studies", "names", "moderators", "predict",
  ])
  if optional_text(o, "model", "reml") != "reml" {
    raise Invalid("regression model must be reml")
  }
  let inference = match optional_text(o, "inference", "modified-hk") {
    "normal" => Normal
    "modified-hk" => ModifiedHK
    _ => raise Invalid("inference must be normal or modified-hk")
  }
  let alpha = match o.get("alpha") {
    None => 0.05
    Some(a) => number_value(a, "alpha")
  }
  let studies : Array[Study] = []
  match required(o, "studies") {
    Array(a) => {
      if a.length() < 2 || a.length() > 512 {
        raise Invalid("study count must be 2..512")
      }
      let kind = study_kind(a[0])
      for s in a {
        if study_kind(s) != kind {
          raise Invalid("mixed effect families are unsupported")
        }
        studies.push(decode_study(s))
      }
    }
    _ => raise Invalid("studies must be an array")
  }
  let names : Array[String] = []
  match required(o, "names") {
    Array(a) => {
      if a.length() > 8 {
        raise Invalid("at most 8 moderator names")
      }
      for n in a {
        names.push(text_value(n, "moderator name"))
      }
    }
    _ => raise Invalid("names must be an array")
  }
  let moderators = numeric_rows(
    required(o, "moderators"),
    studies.length(),
    names.length(),
    "moderators",
  )
  let prediction_rows = match o.get("predict") {
    None => []
    Some(v) => numeric_rows(v, 128, names.length(), "predict")
  }
  let fit = meta_regression(studies, moderators, names, inference~, alpha~)
  let predictions : Array[RegressionPrediction] = []
  for row in prediction_rows {
    predictions.push(fit.predict(row))
  }
  let results : Map[String, Json] = {
    "regression": Json(fit),
    "predictions": Json(predictions),
  }
  let response : Map[String, Json] = {
    "ok": Json(true),
    "version": Json(2),
    "results": Json(results),
  }
  Json(response)
}

///|
fn numeric_rows(
  value : Json,
  limit : Int32,
  width : Int32,
  label : String,
) -> Array[Array[Double]] raise SynthesisError {
  let rows : Array[Array[Double]] = []
  match value {
    Array(a) => {
      if a.length() > limit {
        raise Invalid(label + " row limit exceeded")
      }
      for row in a {
        match row {
          Array(cells) => {
            if cells.length() != width {
              raise Invalid(label + " row width differs from names")
            }
            let numbers : Array[Double] = []
            for c in cells {
              numbers.push(number_value(c, label))
            }
            rows.push(numbers)
          }
          _ => raise Invalid(label + " rows must be arrays")
        }
      }
    }
    _ => raise Invalid(label + " must be an array of rows")
  }
  rows
}
