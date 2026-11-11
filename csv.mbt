///| Quote every cell using doubled quotes and RFC 4180 CRLF record endings.
/// Text labels receive an apostrophe before spreadsheet formula prefixes;
/// numeric cells stay numeric. CSV therefore is a safe report, not lossless storage.
fn csv_text(value : String) -> String {
  let trimmed = value.trim()
  let dangerous = trimmed.has_prefix("=") || trimmed.has_prefix("+") ||
    trimmed.has_prefix("-") || trimmed.has_prefix("@") ||
    value.has_prefix("\t") || value.has_prefix("\r") || value.has_prefix("\n")
  let prefix = if dangerous { "'" } else { "" }
  "\"" + prefix + value.replace_all(old="\"", new="\"\"") + "\""
}

///|
fn csv_number(value : Double) -> String {
  "\"" + value.to_string() + "\""
}

///|
fn csv_record(output : StringBuilder, cells : Array[String]) -> Unit {
  for i in 0..<cells.length() {
    if i > 0 { output.write_string(",") }
    output.write_string(cells[i])
  }
  output.write_string("\r\n")
}

///| Export reproducible study rows and a pooled row with matching analysis options.
/// Every row has the same ten columns; pooled Q is residual Q at selected tau².
pub fn render_csv(studies : Array[Study], model~ : Model = PM,
  inference~ : Inference = ModifiedHK, alpha~ : Double = 0.05) -> String raise SynthesisError {
  let fit = analyze(studies, model~, inference~, alpha~)
  let rows = summarize_studies(studies, model~, inference~, alpha~)
  let output = StringBuilder()
  csv_record(output, ["type", "id", "group", "effect", "variance", "lower", "upper", "weight", "q", "tau2"].map(csv_text))
  for row in rows {
    csv_record(output, [csv_text("study"), csv_text(row.id), csv_text(row.group),
      csv_number(row.effect), csv_number(row.variance),
      csv_number(row.confidence.lower), csv_number(row.confidence.upper),
      csv_number(row.weight), csv_number(row.q_contribution), csv_number(fit.pool.tau2)])
  }
  csv_record(output, [csv_text("pooled"), csv_text(""), csv_text(""),
    csv_number(fit.pool.estimate), csv_number(fit.standard_error * fit.standard_error),
    csv_number(fit.confidence.lower), csv_number(fit.confidence.upper), csv_number(1.0),
    csv_number(fit.pool.residual_q), csv_number(fit.pool.tau2)])
  output.to_string()
}
