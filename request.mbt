///| Parsed protocol options. Construction is always revalidated by execution.
pub(all) struct Request {
  studies : Array[Study]
  model : Model
  inference : Inference
  alpha : Double
  outputs : Array[String]
}

///| Reject misspelled fields rather than silently applying a default policy.
fn exact_keys(object : Map[String, Json], allowed : Array[String]) -> Unit raise SynthesisError {
  for key, _ in object {
    let mut found = false
    for a in allowed { if key == a { found = true } }
    if !found { raise Invalid("unknown field: " + key) }
  }
}

///| Extract required objects without FromJson's implicit numeric conversions.
fn object_value(value : Json, label : String) -> Map[String, Json] raise SynthesisError {
  match value {
    Object(x) => x
    _ => raise Invalid(label + " must be an object")
  }
}

///| Required values distinguish absent fields from explicit null.
fn required(object : Map[String, Json], key : String) -> Json raise SynthesisError {
  match object.get(key) {
    Some(x) => x
    None => raise Invalid("missing field: " + key)
  }
}

///|
fn text_value(value : Json, label : String) -> String raise SynthesisError {
  match value {
    String(s) => s
    _ => raise Invalid(label + " must be a string")
  }
}

///|
fn number_value(value : Json, label : String) -> Double raise SynthesisError {
  match value {
    Number(n, ..) => { require_finite(n, label); n }
    _ => raise Invalid(label + " must be a finite number")
  }
}

///| Only integer-valued in-range Doubles may cross into count arithmetic.
fn count_value(value : Json, label : String) -> Int raise SynthesisError {
  let n = number_value(value, label)
  if n < 0.0 || n > 100000000.0 || n.floor() != n {
    raise Invalid(label + " must be an integer in 0..100000000")
  }
  n.to_int()
}

///|
fn optional_text(object : Map[String, Json], key : String, default : String) -> String raise SynthesisError {
  match object.get(key) {
    None => default
    Some(value) => text_value(value, key)
  }
}

///| Direct inputs explicitly denote effect and sampling variance, never SE.
fn direct_study(value : Json) -> Study raise SynthesisError {
  let o = object_value(value, "study")
  exact_keys(o, ["id", "effect", "variance", "group"])
  study(text_value(required(o, "id"), "id"),
    number_value(required(o, "effect"), "effect"),
    number_value(required(o, "variance"), "variance"),
    group=optional_text(o, "group", ""))
}

///| Parse protocol version 1. JSON nesting, duplicate keys, and total size
/// are bounded before fitting; output choices never name filesystem paths.
pub fn parse_request(text : String) -> Request raise SynthesisError {
  if text.length() > 1048576 { raise Invalid("request exceeds 1048576 UTF-16 code units") }
  let value = try {
    @json.parse(text, max_nesting_depth=16, reject_duplicate_keys=true)
  } catch {
    _ => raise Invalid("invalid JSON, duplicate key, or excessive nesting")
  }
  let o = object_value(value, "request")
  exact_keys(o, ["version", "model", "inference", "alpha", "studies", "outputs"])
  if count_value(required(o, "version"), "version") != 1 { raise Invalid("unsupported protocol version") }
  let model = match optional_text(o, "model", "pm") {
    "fixed" => Fixed
    "dl" => DL
    "pm" => PM
    _ => raise Invalid("model must be fixed, dl or pm")
  }
  let default_inference = if model == Fixed { "normal" } else { "modified-hk" }
  let inference = match optional_text(o, "inference", default_inference) {
    "normal" => Normal
    "modified-hk" => ModifiedHK
    _ => raise Invalid("inference must be normal or modified-hk")
  }
  if model == Fixed && inference == ModifiedHK { raise Invalid("fixed model requires normal inference") }
  let alpha = match o.get("alpha") {
    None => 0.05
    Some(x) => number_value(x, "alpha")
  }
  require_alpha(alpha)
  let studies : Array[Study] = []
  match required(o, "studies") {
    Array(a) => {
      if a.length() < 2 || a.length() > 512 { raise Invalid("study count must be 2..512") }
      for value in a { studies.push(direct_study(value)) }
    }
    _ => raise Invalid("studies must be an array")
  }
  validate_studies(studies, 2)
  let outputs : Array[String] = []
  match o.get("outputs") {
    None => outputs.push("summary")
    Some(Array(a)) => {
      if a.length() == 0 || a.length() > 7 { raise Invalid("outputs count must be 1..7") }
      for v in a {
        let name = text_value(v, "output")
        let allowed = ["summary", "studies", "leave-one-out", "cumulative", "subgroups", "csv", "svg"]
        let mut known = false
        for key in allowed { if key == name { known = true } }
        if !known { raise Invalid("unknown output: " + name) }
        for key in outputs { if key == name { raise Invalid("duplicate output: " + name) } }
        outputs.push(name)
      }
    }
    Some(_) => raise Invalid("outputs must be an array of strings")
  }
  { studies, model, inference, alpha, outputs }
}
