///| Recheck requests built through the typed public constructor as well as JSON.
/// A forged Request cannot bypass validation or introduce filesystem operations.
fn validate_request(request : Request) -> Unit raise SynthesisError {
  validate_studies(request.studies, 2)
  require_alpha(request.alpha)
  if request.model == Fixed && request.inference == ModifiedHK {
    raise Invalid("fixed model requires normal inference")
  }
  if request.outputs.length() < 1 || request.outputs.length() > 7 {
    raise Invalid("outputs count must be 1..7")
  }
  let allowed = ["summary", "studies", "leave-one-out", "cumulative", "subgroups", "csv", "svg"]
  for i in 0..<request.outputs.length() {
    let name = request.outputs[i]
    let mut known = false
    for key in allowed { if name == key { known = true } }
    if !known { raise Invalid("unknown output: " + name) }
    for j in 0..<i {
      if request.outputs[j] == name { raise Invalid("duplicate output: " + name) }
    }
    if name == "leave-one-out" && request.studies.length() > 64 {
      raise Invalid("leave-one-out limit is 64 studies")
    }
    if name == "cumulative" && request.studies.length() > 128 {
      raise Invalid("cumulative limit is 128 studies")
    }
  }
}

///| Execute all requested outputs atomically. One invalid output fails the
/// request rather than returning an apparently successful partial report.
pub fn execute(request : Request) -> Json raise SynthesisError {
  validate_request(request)
  let studies = request.studies
  let model = request.model
  let inference = request.inference
  let alpha = request.alpha
  let results : Map[String, Json] = Map([])
  for name in request.outputs {
    let value = match name {
      "summary" => Json(analyze(studies, model~, inference~, alpha~))
      "studies" => Json(summarize_studies(studies, model~, inference~, alpha~))
      "leave-one-out" => Json(leave_one_out(studies, model~, inference~, alpha~))
      "cumulative" => Json(cumulative(studies, model~, inference~, alpha~))
      "subgroups" => Json(subgroups(studies, model~, inference~, alpha~))
      "csv" => Json(render_csv(studies, model~, inference~, alpha~))
      "svg" => Json(render_forest(studies, model~, inference~, alpha~))
      _ => raise Invalid("unreachable output choice")
    }
    results[name] = value
  }
  let response : Map[String, Json] = {
    "ok": Json(true),
    "version": Json(1),
    "results": Json(results),
  }
  Json(response)
}

///| Stable error envelope; parse failures never echo the original input body.
/// This entry point performs no IO and is usable on every supported backend.
pub fn process_json(text : String) -> String {
  let response = try {
    execute(parse_request(text))
  } catch {
    Invalid(message) => {
      let detail : Map[String, Json] = {
        "code": Json("invalid_input"),
        "message": Json(message),
      }
      let envelope : Map[String, Json] = {
        "ok": Json(false),
        "version": Json(1),
        "error": Json(detail),
      }
      Json(envelope)
    }
  }
  response.stringify()
}
